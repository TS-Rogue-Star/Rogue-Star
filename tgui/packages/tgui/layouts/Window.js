/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { classes } from 'common/react';
import { useDispatch } from 'common/redux';
import { decodeHtmlEntities, toTitleCase } from 'common/string';
import { Component } from 'inferno';
import { backendSuspendStart, useBackend } from '../backend';
import { Icon } from '../components';
import { UI_DISABLED, UI_INTERACTIVE, UI_UPDATE } from '../constants';
import { useDebug } from '../debug';
import { toggleKitchenSink } from '../debug/actions';
import {
  dragStartHandler,
  recallWindowGeometry,
  resizeStartHandler,
  setWindowKey,
} from '../drag';
import { createLogger } from '../logging';
import { Layout } from './Layout';

const logger = createLogger('Window');

const DEFAULT_SIZE = [400, 600];

// RS Add Start: Scaling tool (Lira, December 2025)
const DEFAULT_SCALE = 1;

const normalizeWindowScale = (value) => {
  const scale = Number(value);
  if (!isFinite(scale) || scale <= 0) {
    return DEFAULT_SCALE;
  }
  return scale;
};

const setDocumentWindowScale = (scale) => {
  if (typeof document === 'undefined' || !document.documentElement?.dataset) {
    return;
  }
  document.documentElement.dataset.tguiScale = String(scale);
};
// RS Add End

export class Window extends Component {
  componentDidMount() {
    setDocumentWindowScale(normalizeWindowScale(this.props.scale)); // RS Add: Scaling tool (Lira, December 2025)
    const { suspended } = useBackend(this.context);
    const { canClose = true } = this.props;
    if (suspended) {
      return;
    }
    Byond.winset(Byond.windowId, {
      'can-close': Boolean(canClose),
    });
    logger.log('mounting');
    this.updateGeometry();
  }

  componentDidUpdate(prevProps) {
    const scaleChanged = this.props.scale !== prevProps.scale; // RS Add: Scaling tool (Lira, December 2025)
    // prettier-ignore
    const shouldUpdateGeometry = (
      this.props.width !== prevProps.width
      || this.props.height !== prevProps.height
      || scaleChanged // RS Add: Scaling tool (Lira, December 2025)
    );
    if (shouldUpdateGeometry) {
      this.updateGeometry();
    }
    setDocumentWindowScale(normalizeWindowScale(this.props.scale)); // RS Add: Scaling tool (Lira, December 2025)
  }

  // RS Add: Scaling tool (Lira, December 2025)
  componentWillUnmount() {
    setDocumentWindowScale(DEFAULT_SCALE);
  }

  updateGeometry() {
    const { config } = useBackend(this.context);
    const scale = normalizeWindowScale(this.props.scale); // RS Add: Scaling tool (Lira, December 2025)
    const options = {
      size: DEFAULT_SIZE,
      ...config.window,
    };
    if (this.props.width && this.props.height) {
      options.size = [this.props.width, this.props.height];
    }
    // RS Add: Scaling tool (Lira, December 2025)
    if (Array.isArray(options.size) && options.size.length >= 2) {
      options.size = [
        Math.round(options.size[0] * scale),
        Math.round(options.size[1] * scale),
      ];
    }
    if (config.window?.key) {
      setWindowKey(config.window.key);
    }
    recallWindowGeometry(options);
  }

  render() {
    const scale = normalizeWindowScale(this.props.scale); // RS Add: Scaling tool (Lira, December 2025)
    const {
      canClose = true,
      theme,
      title,
      children,
      buttons,
      onClose, // RS Add: Close trigger (Lira, November 2025)
      statusIcon, // RS Add: Status Icon (Lira, November 2025)
    } = this.props;
    const { config, suspended } = useBackend(this.context);
    const { debugLayout } = useDebug(this.context);
    const dispatch = useDispatch(this.context);
    const fancy = config.window?.fancy;
    // Determine when to show dimmer
    // prettier-ignore
    const showDimmer = config.user && (
      config.user.observer
        ? config.status < UI_DISABLED
        : config.status < UI_INTERACTIVE
    );
    const windowContents = // RS Add: Scaling tool (Lira, December 2025)
      (
        <>
          <TitleBar
            className="Window__titleBar"
            title={!suspended && (title || decodeHtmlEntities(config.title))}
            status={config.status}
            fancy={fancy}
            statusIcon={statusIcon} // RS Add: Set status icon (Lira, November 2025)
            onDragStart={dragStartHandler}
            onClose={() => {
              // RS Add: Close function (Lira, November 2025)
              if (typeof onClose === 'function') {
                try {
                  onClose();
                } catch (error) {
                  logger.error('onClose handler threw', error);
                }
              }
              logger.log('pressed close');
              dispatch(backendSuspendStart());
            }}
            canClose={canClose}>
            {buttons}
          </TitleBar>
          <div
            className={classes([
              'Window__rest',
              debugLayout && 'debug-layout',
            ])}>
            {!suspended && children}
            {showDimmer && <div className="Window__dimmer" />}
          </div>
          {fancy && (
            <>
              <div
                className="Window__resizeHandle__e"
                onMousedown={resizeStartHandler(1, 0)}
              />
              <div
                className="Window__resizeHandle__s"
                onMousedown={resizeStartHandler(0, 1)}
              />
              <div
                className="Window__resizeHandle__se"
                onMousedown={resizeStartHandler(1, 1)}
              />
            </>
          )}
        </>
      );

    // RS Add Start: Scaling tool (Lira, December 2025)
    const scaled = scale !== DEFAULT_SCALE;
    return (
      <Layout className="Window" theme={theme}>
        {(scaled && (
          <div
            style={`position:absolute;top:0;left:0;width:${
              100 / scale
            }%;height:${100 / scale}%;transform:scale(${scale});transform-origin:0 0;`}>
            {windowContents}
          </div>
        )) ||
          windowContents}
      </Layout>
    );
    // RS Add End
  }
}

const WindowContent = (props) => {
  const { className, fitted, children, ...rest } = props;
  return (
    <Layout.Content
      className={classes(['Window__content', className])}
      {...rest}>
      {(fitted && children) || (
        <div className="Window__contentPadding">{children}</div>
      )}
    </Layout.Content>
  );
};

Window.Content = WindowContent;

const statusToColor = (status) => {
  switch (status) {
    case UI_INTERACTIVE:
      return 'good';
    case UI_UPDATE:
      return 'average';
    case UI_DISABLED:
    default:
      return 'bad';
  }
};

const TitleBar = (props, context) => {
  const {
    className,
    title,
    status,
    canClose,
    fancy,
    onDragStart,
    onClose,
    children,
    statusIcon, // RS Add: Status icon (Lira, November 2025)
  } = props;
  const dispatch = useDispatch(context);
  // prettier-ignore
  const finalTitle = (
    typeof title === 'string'
    && title === title.toLowerCase()
    && toTitleCase(title)
    || title
  );
  return (
    <div className={classes(['TitleBar', className])}>
      {/* RS Add: Status Icon (Lira, November 2025) */}
      {statusIcon ||
        (status === undefined && (
          <Icon className="TitleBar__statusIcon" name="tools" opacity={0.5} />
        )) || (
          <Icon
            className="TitleBar__statusIcon"
            color={statusToColor(status)}
            name="eye"
          />
        )}
      <div
        className="TitleBar__dragZone"
        onMousedown={(e) => fancy && onDragStart(e)}
      />
      <div className="TitleBar__title">
        {finalTitle}
        {!!children && <div className="TitleBar__buttons">{children}</div>}
      </div>
      {process.env.NODE_ENV !== 'production' && (
        <div
          className="TitleBar__devBuildIndicator"
          onClick={() => dispatch(toggleKitchenSink())}>
          <Icon name="bug" />
        </div>
      )}
      {Boolean(fancy && canClose) && (
        <div
          className="TitleBar__close TitleBar__clickable"
          // IE8: Synthetic onClick event doesn't work on IE8.
          // IE8: Use a plain character instead of a unicode symbol.
          // eslint-disable-next-line react/no-unknown-property
          onclick={onClose}>
          {Byond.IS_LTE_IE8 ? 'x' : '×'}
        </div>
      )}
    </div>
  );
};
