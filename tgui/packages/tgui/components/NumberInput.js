/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

// ///////////////////////////////////////////////////////////////////////////
// Updated by Lira for Rogue Star September 2025 to add scroll wheel support//
// ///////////////////////////////////////////////////////////////////////////

import { clamp } from 'common/math';
import { classes, pureComponentHooks } from 'common/react';
import { throttle } from 'common/timer';
import { Component, createRef } from 'inferno';
import { AnimatedNumber } from './AnimatedNumber';
import { Box } from './Box';

const DEFAULT_UPDATE_RATE = 400;
const DEFAULT_WHEEL_UPDATE_RATE = 50; // RS Add: Limit how often wheel-driven changes propagate to backend (ms) (Lira, September 2025)

export class NumberInput extends Component {
  constructor(props) {
    super(props);
    const { value } = props;
    this.inputRef = createRef();
    this.state = {
      value,
      dragging: false,
      editing: false,
      internalValue: null,
      origin: null,
      suppressingFlicker: false,
    };

    // Suppresses flickering while the value propagates through the backend
    this.flickerTimer = null;
    this.suppressFlicker = () => {
      const { suppressFlicker } = this.props;
      if (suppressFlicker > 0) {
        this.setState({
          suppressingFlicker: true,
        });
        clearTimeout(this.flickerTimer);
        this.flickerTimer = setTimeout(
          () =>
            this.setState({
              suppressingFlicker: false,
            }),
          suppressFlicker
        );
      }
    };

    // RS Add: Throttle for wheel-driven updates to avoid event spam (Lira, September 2025)
    this.commitWheelThrottled = throttle((snappedValue) => {
      const { onChange, onDrag } = this.props;
      this.suppressFlicker();
      if (onChange) {
        onChange(undefined, snappedValue);
      }
      if (onDrag) {
        onDrag(undefined, snappedValue);
      }
    }, this.props.wheelUpdateRate || DEFAULT_WHEEL_UPDATE_RATE);

    this.handleDragStart = (e) => {
      const { value } = this.props;
      const { editing } = this.state;
      if (editing) {
        return;
      }
      document.body.style['pointer-events'] = 'none';
      this.ref = e.target;
      this.setState({
        dragging: false,
        origin: e.screenY,
        value,
        internalValue: value,
      });
      this.timer = setTimeout(() => {
        this.setState({
          dragging: true,
        });
      }, 250);
      this.dragInterval = setInterval(() => {
        const { dragging, value } = this.state;
        const { onDrag } = this.props;
        if (dragging && onDrag) {
          onDrag(e, value);
        }
      }, this.props.updateRate || DEFAULT_UPDATE_RATE);
      document.addEventListener('mousemove', this.handleDragMove);
      document.addEventListener('mouseup', this.handleDragEnd);
    };

    // RS Edit: Prevent extended decimals on drag (Lira, October 2025)
    this.handleDragMove = (e) => {
      const { minValue, maxValue, step, stepPixelSize } = this.props;
      this.setState((prevState) => {
        const state = { ...prevState };
        const offset = state.origin - e.screenY;
        if (prevState.dragging) {
          const effectiveStep = Number.isFinite(step) && step !== 0 ? step : 1;
          const stepOffset = Number.isFinite(minValue)
            ? minValue % effectiveStep
            : 0;
          // Translate mouse movement to value
          // Give it some headroom (by increasing clamp range by 1 step)
          state.internalValue = clamp(
            state.internalValue + (offset * effectiveStep) / stepPixelSize,
            minValue - effectiveStep,
            maxValue + effectiveStep
          );
          // Clamp the final value
          let snapped =
            Math.round((state.internalValue - stepOffset) / effectiveStep) *
              effectiveStep +
            stepOffset;
          snapped = clamp(snapped, minValue, maxValue);
          state.value = parseFloat(snapped.toFixed(10));
          state.origin = e.screenY;
        } else if (Math.abs(offset) > 4) {
          state.dragging = true;
        }
        return state;
      });
    };

    this.handleDragEnd = (e) => {
      const { onChange, onDrag } = this.props;
      const { dragging, value, internalValue } = this.state;
      document.body.style['pointer-events'] = 'auto';
      clearTimeout(this.timer);
      clearInterval(this.dragInterval);
      this.setState({
        dragging: false,
        editing: !dragging,
        origin: null,
      });
      document.removeEventListener('mousemove', this.handleDragMove);
      document.removeEventListener('mouseup', this.handleDragEnd);
      if (dragging) {
        this.suppressFlicker();
        if (onChange) {
          onChange(e, value);
        }
        if (onDrag) {
          onDrag(e, value);
        }
      } else if (this.inputRef) {
        const input = this.inputRef.current;
        input.value = internalValue;
        // IE8: Dies when trying to focus a hidden element
        // (Error: Object does not support this action)
        try {
          input.focus();
          input.select();
        } catch {}
      }
    };

    // RS Add: Adds scroll wheel support (Lira, September 2025)
    this.handleWheel = (e) => {
      const { editing, dragging } = this.state;
      const {
        minValue,
        maxValue,
        step,
        onChange,
        onDrag,
        wheelStep,
        wheelStepShift,
        wheelAllowWhileEditing,
      } = this.props;
      // Ignore scripted events and wheel during drag
      if ((typeof e.isTrusted === 'boolean' && !e.isTrusted) || dragging) {
        return;
      }
      if (editing && wheelAllowWhileEditing === false) {
        return;
      }
      // Determine scroll direction: wheel up should increase value
      let direction = 0;
      if (typeof e.deltaY === 'number') {
        direction = e.deltaY < 0 ? 1 : -1;
      } else if (typeof e.wheelDelta === 'number') {
        direction = e.wheelDelta > 0 ? 1 : -1;
      }
      if (direction === 0) {
        return;
      }
      // Determine wheel delta size
      const effectiveStep = Number.isFinite(step) && step > 0 ? step : 1;
      const baseWheel = Number.isFinite(wheelStep) ? wheelStep : effectiveStep;
      const shiftWheel = Number.isFinite(wheelStepShift)
        ? wheelStepShift
        : baseWheel * 10;
      const delta = e.shiftKey ? shiftWheel : baseWheel;
      // If delta is zero, treat as disabled for this control
      if (!Number.isFinite(delta) || delta === 0) {
        return;
      }
      // Compute next value and snap to step like dragging logic
      const stepOffset = Number.isFinite(minValue)
        ? minValue % effectiveStep
        : 0;
      const currentValue = Number.isFinite(this.state.value)
        ? this.state.value
        : this.props.value;
      const internal = currentValue + direction * delta;
      // Snap using rounding to avoid floating-point issues
      let snapped =
        Math.round((internal - stepOffset) / effectiveStep) * effectiveStep +
        stepOffset;
      // Reduce FP noise
      snapped = parseFloat(snapped.toFixed(10));
      snapped = clamp(snapped, minValue, maxValue);
      // If nothing would change, return early
      if (snapped === currentValue) {
        if (e.preventDefault) e.preventDefault();
        if (e.stopPropagation) e.stopPropagation();
        return;
      }
      this.setState({ value: snapped });
      if (editing && this.inputRef && this.inputRef.current) {
        try {
          this.inputRef.current.value = String(snapped);
        } catch {}
      }
      // Throttle backend updates to avoid event spam
      this.commitWheelThrottled(snapped);
      if (e.preventDefault) e.preventDefault();
      if (e.stopPropagation) e.stopPropagation();
    };
    // RS Add End
  }

  render() {
    const {
      dragging,
      editing,
      value: intermediateValue,
      suppressingFlicker,
    } = this.state;
    const {
      className,
      fluid,
      animated,
      value,
      unit,
      minValue,
      maxValue,
      height,
      width,
      lineHeight,
      fontSize,
      format,
      onChange,
      onDrag,
    } = this.props;
    let displayValue = value;
    if (dragging || suppressingFlicker) {
      displayValue = intermediateValue;
    }

    // prettier-ignore
    const contentElement = (
      <div className="NumberInput__content" unselectable={Byond.IS_LTE_IE8}>
        {
          (animated && !dragging && !suppressingFlicker) ?
            (<AnimatedNumber value={displayValue} format={format} />) :
            (format ? format(displayValue) : displayValue)
        }

        {unit ? ' ' + unit : ''}
      </div>
    );

    return (
      <Box
        className={classes([
          'NumberInput',
          fluid && 'NumberInput--fluid',
          className,
        ])}
        minWidth={width}
        minHeight={height}
        lineHeight={lineHeight}
        fontSize={fontSize}
        onMouseDown={this.handleDragStart}
        // RS Add: Adds scroll wheel support (Lira, September 2025)
        onWheel={this.handleWheel}>
        <div className="NumberInput__barContainer">
          <div
            className="NumberInput__bar"
            style={{
              // prettier-ignore
              height: clamp(
                (displayValue - minValue) / (maxValue - minValue) * 100,
                0, 100) + '%',
            }}
          />
        </div>
        {contentElement}
        <input
          ref={this.inputRef}
          className="NumberInput__input"
          style={{
            display: !editing ? 'none' : undefined,
            height: height,
            'line-height': lineHeight,
            'font-size': fontSize,
          }}
          onWheel={this.handleWheel} // RS Add: Adds scroll wheel support (Lira, September 2025)
          onBlur={(e) => {
            if (!editing) {
              return;
            }
            const value = clamp(parseFloat(e.target.value), minValue, maxValue);
            if (Number.isNaN(value)) {
              this.setState({
                editing: false,
              });
              return;
            }
            this.setState({
              editing: false,
              value,
            });
            this.suppressFlicker();
            if (onChange) {
              onChange(e, value);
            }
            if (onDrag) {
              onDrag(e, value);
            }
          }}
          onKeyDown={(e) => {
            if (e.keyCode === 13) {
              // prettier-ignore
              const value = clamp(
                parseFloat(e.target.value),
                minValue,
                maxValue
              );
              if (Number.isNaN(value)) {
                this.setState({
                  editing: false,
                });
                return;
              }
              this.setState({
                editing: false,
                value,
              });
              this.suppressFlicker();
              if (onChange) {
                onChange(e, value);
              }
              if (onDrag) {
                onDrag(e, value);
              }
              return;
            }
            if (e.keyCode === 27) {
              this.setState({
                editing: false,
              });
              return;
            }
          }}
        />
      </Box>
    );
  }
}

NumberInput.defaultHooks = pureComponentHooks;
NumberInput.defaultProps = {
  minValue: -Infinity,
  maxValue: +Infinity,
  step: 1,
  stepPixelSize: 1,
  suppressFlicker: 50,
  // RS Add Start: Adds scroll wheel support (Lira, September 2025)
  wheelStep: null,
  wheelStepShift: null,
  wheelAllowWhileEditing: false,
  wheelUpdateRate: DEFAULT_WHEEL_UPDATE_RATE,
  // RS Add End
};
