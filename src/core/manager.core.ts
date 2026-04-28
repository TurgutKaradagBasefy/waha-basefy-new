import {
  Inject,
  Injectable,
  NotFoundException,
  OnModuleInit,
  UnprocessableEntityException,
} from '@nestjs/common';
import {
  AppsService,
  IAppsService,
} from '@waha/apps/app_sdk/services/IAppsService';
import { EngineBootstrap } from '@waha/core/abc/EngineBootstrap';
import { GowsEngineConfigService } from '@waha/core/config/GowsEngineConfigService';
import { WPPEngineConfigService } from '@waha/core/config/WPPEngineConfigService';
import { WebJSEngineConfigService } from '@waha/core/config/WebJSEngineConfigService';
import { WhatsappSessionGoWSCore } from '@waha/core/engines/gows/session.gows.core';
import { WebhookConductor } from '@waha/core/integrations/webhooks/WebhookConductor';
import { MediaStorageFactory } from '@waha/core/media/MediaStorageFactory';
import { DefaultMap } from '@waha/utils/DefaultMap';
import { getPinoLogLevel, LoggerBuilder } from '@waha/utils/logging';
import { promiseTimeout, sleep } from '@waha/utils/promiseTimeout';
import { complete } from '@waha/utils/reactive/complete';
import { SwitchObservable } from '@waha/utils/reactive/SwitchObservable';
import { PinoLogger } from 'nestjs-pino';
import { merge, Observable, retry, share } from 'rxjs';
import { map } from 'rxjs/operators';

import { getNamespace, getSessionNamespace } from '../config';
import { WhatsappConfigService } from '../config.service';
import {
  WAHAEngine,
  WAHAEvents,
  WAHASessionStatus,
} from '../structures/enums.dto';
import {
  ProxyConfig,
  SessionConfig,
  SessionDetailedInfo,
  SessionDTO,
  SessionInfo,
} from '../structures/sessions.dto';
import { WebhookConfig } from '../structures/webhooks.config.dto';
import { populateSessionInfo, SessionManager } from './abc/manager.abc';
import { SessionParams, WhatsappSession } from './abc/session.abc';
import { EngineConfigService } from './config/EngineConfigService';
import { WhatsappSessionNoWebCore } from './engines/noweb/session.noweb.core';
import { WhatsappSessionWPPCore } from './engines/wpp/session.wpp.core';
import { WhatsappSessionWebJSCore } from './engines/webjs/session.webjs.core';
import { getProxyConfig } from './helpers.proxy';
import { MediaManager } from './media/MediaManager';
import { LocalSessionAuthRepository } from './storage/LocalSessionAuthRepository';
import { LocalStoreCore } from './storage/LocalStoreCore';
import { CoreApiKeyRepository } from './storage/CoreApiKeyRepository';

//
// Session status markers
//
const SESSION_REMOVED = Symbol('REMOVED');
const SESSION_STOPPED = Symbol('STOPPED');

type SessionStatus = WhatsappSession | typeof SESSION_REMOVED | typeof SESSION_STOPPED;

@Injectable()
export class SessionManagerCore extends SessionManager implements OnModuleInit {
  SESSION_STOP_TIMEOUT = 3000;

  //
  // Multi-session support: Map of session name to session object
  //
  private sessions: Map<string, WhatsappSession | SessionStatus> = new Map();
  private sessionConfigs: Map<string, SessionConfig> = new Map();

  protected readonly EngineClass: typeof WhatsappSession;
  protected events2: Map<string, DefaultMap<WAHAEvents, SwitchObservable<any>>> =
    new Map();
  protected readonly engineBootstrap: EngineBootstrap;

  constructor(
    config: WhatsappConfigService,
    private engineConfigService: EngineConfigService,
    private webjsEngineConfigService: WebJSEngineConfigService,
    private wppEngineConfigService: WPPEngineConfigService,
    gowsConfigService: GowsEngineConfigService,
    log: PinoLogger,
    private mediaStorageFactory: MediaStorageFactory,
    @Inject(AppsService)
    appsService: IAppsService,
  ) {
    super(log, config, gowsConfigService, appsService);
    const engineName = this.engineConfigService.getDefaultEngineName();
    this.EngineClass = this.getEngine(engineName);
    this.engineBootstrap = this.getEngineBootstrap(engineName);

    this.store = new LocalStoreCore(getNamespace(), getSessionNamespace());
    this.sessionAuthRepository = new LocalSessionAuthRepository(this.store);
    this.clearStorage().catch((error) => {
      this.log.error({ error }, 'Error while clearing storage');
    });
  }

  protected getEngine(engine: WAHAEngine): typeof WhatsappSession {
    if (engine === WAHAEngine.WEBJS) {
      return WhatsappSessionWebJSCore;
    } else if (engine === WAHAEngine.WPP) {
      return WhatsappSessionWPPCore;
    } else if (engine === WAHAEngine.NOWEB) {
      return WhatsappSessionNoWebCore;
    } else if (engine === WAHAEngine.GOWS) {
      return WhatsappSessionGoWSCore;
    } else {
      throw new NotFoundException(`Unknown whatsapp engine '${engine}'.`);
    }
  }

  //
  // Event stream management
  //
  private getEventStream(
    sessionName: string,
  ): DefaultMap<WAHAEvents, SwitchObservable<any>> {
    if (!this.events2.has(sessionName)) {
      this.events2.set(
        sessionName,
        new DefaultMap<WAHAEvents, SwitchObservable<any>>(
          (key) =>
            new SwitchObservable((obs$) => {
              return obs$.pipe(retry(), share());
            }),
        ),
      );
    }
    return this.events2.get(sessionName)!;
  }

  async beforeApplicationShutdown(signal?: string) {
    const sessionNames = Array.from(this.sessions.keys());
    for (const name of sessionNames) {
      await this.stop(name, true);
    }
    this.stopEvents();
    await this.engineBootstrap.shutdown();
  }

  async onApplicationBootstrap() {
    this.apiKeyRepository = new CoreApiKeyRepository();
    await this.engineBootstrap.bootstrap();
    this.startPredefinedSessions();
  }

  private async clearStorage() {
    const storage = await this.mediaStorageFactory.build(
      'all',
      this.log.logger.child({ name: 'Storage' }),
    );
    await storage.purge();
  }

  //
  // API Methods
  //
  async exists(name: string): Promise<boolean> {
    const status = this.sessions.get(name);
    return status !== SESSION_REMOVED && status !== undefined;
  }

  isRunning(name: string): boolean {
    const status = this.sessions.get(name);
    return status !== SESSION_STOPPED && status !== SESSION_REMOVED && status !== undefined;
  }

  async upsert(name: string, config?: SessionConfig): Promise<void> {
    if (config) {
      this.sessionConfigs.set(name, config);
    }
  }

  async start(name: string): Promise<SessionDTO> {
    const existingSession = this.sessions.get(name);
    if (existingSession && existingSession !== SESSION_STOPPED && existingSession !== undefined) {
      throw new UnprocessableEntityException(
        `Session '${name}' is already started.`,
      );
    }

    this.log.info({ session: name }, `Starting session...`);
    const logger = this.log.logger.child({ session: name });
    const sessionConfig = this.sessionConfigs.get(name);
    logger.level = getPinoLogLevel(sessionConfig?.debug);
    const loggerBuilder: LoggerBuilder = logger;

    const storage = await this.mediaStorageFactory.build(
      name,
      loggerBuilder.child({ name: 'Storage' }),
    );
    await storage.init();
    const mediaManager = new MediaManager(
      storage,
      this.config.mimetypes,
      loggerBuilder.child({ name: 'MediaManager' }),
    );

    const webhook = new WebhookConductor(loggerBuilder);
    const proxyConfig = this.getProxyConfig(name);
    const sessionParams: SessionParams = {
      name,
      mediaManager,
      loggerBuilder,
      printQR: this.engineConfigService.shouldPrintQR,
      sessionStore: this.store,
      proxyConfig: proxyConfig,
      sessionConfig: sessionConfig,
      ignore: this.ignoreChatsConfig(sessionConfig ?? {}),
    };

    if (this.EngineClass === WhatsappSessionWebJSCore) {
      sessionParams.engineConfig = this.webjsEngineConfigService.getConfig();
    } else if (this.EngineClass === WhatsappSessionWPPCore) {
      sessionParams.engineConfig = this.wppEngineConfigService.getConfig();
    } else if (this.EngineClass === WhatsappSessionGoWSCore) {
      sessionParams.engineConfig = this.gowsConfigService.getConfig();
    }

    await this.sessionAuthRepository.init(name);
    // @ts-ignore
    const session = new this.EngineClass(sessionParams);
    this.sessions.set(name, session);
    this.updateSessionEvents(name, session);

    // configure webhooks
    const webhooks = this.getWebhooks(name);
    webhook.configure(session, webhooks);

    // Apps
    try {
      await this.appsService.beforeSessionStart(session, this.store);
    } catch (e) {
      logger.error(`Apps Error: ${e}`);
      session.status = WAHASessionStatus.FAILED;
    }

    // start session
    if (session.status !== WAHASessionStatus.FAILED) {
      await session.start();
      logger.info('Session has been started.');
      // Apps
      await this.appsService.afterSessionStart(session, this.store);
    }

    // Apps
    await this.appsService.afterSessionStart(session, this.store);

    return {
      name: session.name,
      status: session.status,
      config: session.sessionConfig,
    };
  }

  private updateSessionEvents(name: string, session: WhatsappSession) {
    const eventStream = this.getEventStream(name);
    for (const eventName in WAHAEvents) {
      const event = WAHAEvents[eventName as keyof typeof WAHAEvents];
      const stream$ = session
        .getEventObservable(event)
        .pipe(map(populateSessionInfo(event, session)));
      (eventStream.get(event) as any).switch(stream$);
    }
  }

  getSessionEvent(sessionName: string, event: WAHAEvents): Observable<any> {
    const eventStream = this.getEventStream(sessionName);
    return eventStream.get(event);
  }

  async stop(name: string, silent: boolean): Promise<void> {
    if (!this.isRunning(name)) {
      this.log.debug({ session: name }, `Session is not running.`);
      return;
    }

    this.log.info({ session: name }, `Stopping session...`);
    try {
      const session = this.getSession(name);
      await session.stop();
    } catch (err) {
      this.log.warn(`Error while stopping session '${name}'`);
      if (!silent) {
        throw err;
      }
    }
    this.log.info({ session: name }, `Session has been stopped.`);
    this.sessions.set(name, SESSION_STOPPED);
    await sleep(this.SESSION_STOP_TIMEOUT);
  }

  async unpair(name: string) {
    const session = this.sessions.get(name);
    if (!session || session === SESSION_STOPPED || session === SESSION_REMOVED) {
      return;
    }

    const activeSession = session as WhatsappSession;
    this.log.info({ session: name }, 'Unpairing the device from account...');
    await activeSession.unpair().catch((err) => {
      this.log.warn(`Error while unpairing from device: ${err}`);
    });
    await sleep(1000);
  }

  async logout(name: string): Promise<void> {
    await this.sessionAuthRepository.clean(name);
  }

  async delete(name: string): Promise<void> {
    await this.appsService.removeBySession(this, name);
    this.sessions.set(name, SESSION_REMOVED);
    this.sessionConfigs.delete(name);
    this.events2.delete(name);
  }

  /**
   * Combine per session and global webhooks
   */
  private getWebhooks(sessionName: string) {
    let webhooks: WebhookConfig[] = [];
    const sessionConfig = this.sessionConfigs.get(sessionName);
    if (sessionConfig?.webhooks) {
      webhooks = webhooks.concat(sessionConfig.webhooks);
    }
    const globalWebhookConfig = this.config.getWebhookConfig();
    if (globalWebhookConfig) {
      webhooks.push(globalWebhookConfig);
    }
    return webhooks;
  }

  /**
   * Get either session's or global proxy if defined
   */
  protected getProxyConfig(sessionName: string): ProxyConfig | undefined {
    const sessionConfig = this.sessionConfigs.get(sessionName);
    if (sessionConfig?.proxy) {
      return sessionConfig.proxy;
    }
    const session = this.sessions.get(sessionName);
    if (!session || session === SESSION_STOPPED || session === SESSION_REMOVED) {
      return undefined;
    }
    const sessions = { [sessionName]: session as WhatsappSession };
    return getProxyConfig(this.config, sessions, sessionName);
  }

  getSession(name: string): WhatsappSession {
    const session = this.sessions.get(name);
    if (!session || session === SESSION_STOPPED || session === SESSION_REMOVED) {
      throw new NotFoundException(
        `We didn't find a session with name '${name}'.\n` +
          `Please start it first by using POST /api/sessions/${name}/start request`,
      );
    }
    return session as WhatsappSession;
  }

  async getSessions(all: boolean): Promise<SessionInfo[]> {
    const result: SessionInfo[] = [];

    for (const [name, sessionStatus] of this.sessions.entries()) {
      if (sessionStatus === SESSION_REMOVED) {
        continue;
      }

      const sessionConfig = this.sessionConfigs.get(name);

      if (sessionStatus === SESSION_STOPPED) {
        if (all) {
          result.push({
            name: name,
            status: WAHASessionStatus.STOPPED,
            config: sessionConfig,
            me: undefined,
            presence: null,
            timestamps: {
              activity: null,
            },
          });
        }
        continue;
      }

      const session = sessionStatus as WhatsappSession;
      const me = session?.getSessionMeInfo();
      result.push({
        name: session.name,
        status: session.status,
        config: session.sessionConfig,
        me: me || undefined,
        presence: session.presence,
        timestamps: {
          activity: session?.getLastActivityTimestamp() || null,
        },
      });
    }

    return result;
  }

  private async fetchEngineInfo(session: WhatsappSession) {
    let engineInfo = {};
    if (session) {
      try {
        engineInfo = await promiseTimeout(1000, session.getEngineInfo());
      } catch (error) {
        this.log.debug(
          { session: session.name, error: `${error}` },
          'Can not get engine info',
        );
      }
    }
    const engine = {
      engine: session?.engine,
      ...engineInfo,
    };
    return engine;
  }

  async getSessionInfo(name: string): Promise<SessionDetailedInfo | null> {
    const sessions = await this.getSessions(true);
    const session = sessions.find((s) => s.name === name);
    if (!session) {
      return null;
    }

    let engine = {};
    const runningSession = this.sessions.get(name);
    if (runningSession && runningSession !== SESSION_STOPPED && runningSession !== SESSION_REMOVED) {
      engine = await this.fetchEngineInfo(runningSession as WhatsappSession);
    }

    return {
      ...session,
      engine: engine,
    };
  }

  protected stopEvents() {
    for (const eventStream of this.events2.values()) {
      complete(eventStream);
    }
  }

  async onModuleInit() {
    await this.init();
  }

  async init() {
    await this.store.init();
    const knex = this.store.getWAHADatabase();
    await this.appsService.migrate(knex);
  }
}