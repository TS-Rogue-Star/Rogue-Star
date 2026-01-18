/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { canRender, classes } from 'common/react';
import { Component, createRef, InfernoNode, RefObject } from 'inferno';
import { addScrollableNode, removeScrollableNode } from '../events';
import { BoxProps, computeBoxClassName, computeBoxProps } from './Box';

interface SectionProps extends BoxProps {
  readonly className?: string;
  readonly title?: string | InfernoElement<string>;
  readonly buttons?: InfernoNode;
  readonly fill?: boolean;
  readonly fitted?: boolean;
  readonly scrollable?: boolean;
  readonly scrollableHorizontal?: boolean;
  readonly flexGrow?: boolean; // VOREStation Addition
  readonly noTopPadding?: boolean; // VOREStation Addition
  readonly stretchContents?: boolean; // VOREStation Addition
  /** @deprecated This property no longer works, please remove it. */
  readonly level?: never;
  /** @deprecated Please use `scrollable` property */
  readonly overflowY?: never;
  /** @member Allows external control of scrolling. */
  readonly scrollableRef?: RefObject<HTMLDivElement>;
  /** @member Callback function for the `scroll` event */
  readonly onScroll?: (this: GlobalEventHandlers, ev: Event) => any;
}

export class Section extends Component<SectionProps> {
  scrollableRef: RefObject<HTMLDivElement>;
  scrollable: boolean;
  onScroll?: (this: GlobalEventHandlers, ev: Event) => any;
  scrollableHorizontal: boolean;

  constructor(props) {
    super(props);
    this.scrollableRef = props.scrollableRef || createRef();
    this.scrollable = props.scrollable;
    this.onScroll = props.onScroll;
    this.scrollableHorizontal = props.scrollableHorizontal;
  }

  componentDidMount() {
    if (this.scrollable || this.scrollableHorizontal) {
      addScrollableNode(this.scrollableRef.current as HTMLElement);
      if (this.onScroll && this.scrollableRef.current) {
        this.scrollableRef.current.onscroll = this.onScroll;
      }
    }
  }

  componentWillUnmount() {
    if (this.scrollable || this.scrollableHorizontal) {
      removeScrollableNode(this.scrollableRef.current as HTMLElement);
    }
  }

  render() {
    const {
      className,
      title,
      buttons,
      fill,
      fitted,
      scrollable,
      scrollableHorizontal,
      flexGrow, // VOREStation Addition
      noTopPadding, // VOREStation Addition
      stretchContents, // VOREStation Addition
      children,
      onScroll,
      ...rest
    } = this.props;
    const hasTitle = canRender(title) || canRender(buttons);
    return (
      <div
        className={classes([
          'Section',
          Byond.IS_LTE_IE8 && 'Section--iefix',
          fill && 'Section--fill',
          fitted && 'Section--fitted',
          scrollable && 'Section--scrollable',
          scrollableHorizontal && 'Section--scrollableHorizontal',
          flexGrow && 'Section--flex', // VOREStation Addition
          className,
          computeBoxClassName(rest),
        ])}
        {...computeBoxProps(rest)}>
        {hasTitle && (
          <div className="Section__title">
            <span className="Section__titleText">{title}</span>
            <div className="Section__buttons">{buttons}</div>
          </div>
        )}
        <div className="Section__rest">
          {/* Vorestation Edit Start */}
          <div
            ref={this.scrollableRef}
            className={classes([
              'Section__content',
              !!stretchContents && 'Section__content--stretchContents',
              !!noTopPadding && 'Section__content--noTopPadding',
            ])}>
            {children}
          </div>
          {/* Vorestation Edit End */}
        </div>
      </div>
    );
  }
}
