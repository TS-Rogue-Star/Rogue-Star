import { createPopper, VirtualElement } from '@popperjs/core';
import { classes } from 'common/react';
import { Component, findDOMFromVNode, InfernoNode, render } from 'inferno'; // RS Edit: Inferno 7 to 9 (Lira, January 2026)
import { tguiScalePopperModifier } from '../utils/uiScale'; // RS Add: Scaling tool (Lira, December 2025)
import { Box, BoxProps } from './Box';
import { Button } from './Button';
import { Icon } from './Icon';
import { Stack } from './Stack';

export interface DropdownEntry {
  displayText: string | number | InfernoNode;
  value: string | number | Enumerator;
}

type DropdownUniqueProps = {
  readonly options: string[] | DropdownEntry[];
  readonly icon?: string;
  readonly iconRotation?: number;
  readonly clipSelectedText?: boolean;
  readonly dropdownStyle?: string; // RS Add: Improvements for emote interface (Lira, February 2026)
  readonly width?: string;
  readonly menuWidth?: string;
  readonly over?: boolean;
  readonly color?: string;
  readonly nochevron?: boolean;
  readonly displayText?: string | number | InfernoNode;
  readonly onClick?: (event) => void;
  // you freaks really are just doing anything with this shit
  readonly selected?: any;
  readonly onSelected?: (selected: any) => void;
  readonly buttons?: boolean;
};

export type DropdownProps = BoxProps & DropdownUniqueProps;

const DEFAULT_OPTIONS = {
  placement: 'left-start',
  modifiers: [
    {
      name: 'eventListeners',
      enabled: false,
    },
    tguiScalePopperModifier, // RS Add: Scaling tool (Lira, December 2025)
  ],
};
const NULL_RECT: DOMRect = {
  width: 0,
  height: 0,
  top: 0,
  right: 0,
  bottom: 0,
  left: 0,
  x: 0,
  y: 0,
  toJSON: () => null,
} as const;

type DropdownState = {
  selected?: string;
  open: boolean;
};

const DROPDOWN_DEFAULT_CLASSNAMES = 'Layout Dropdown__menu';
const DROPDOWN_SCROLL_CLASSNAMES = 'Layout Dropdown__menu-scroll';
const VIEWPORT_MENU_PADDING = 8; // RS Add: Improvements for emote interface (Lira, February 2026)
const MIN_ROGUE_STAR_MENU_HEIGHT = 120; // RS Add: emote interface tweaks (Lira, February 2026)

export class Dropdown extends Component<DropdownProps, DropdownState> {
  static renderedMenu: HTMLDivElement | undefined;
  static singletonPopper: ReturnType<typeof createPopper> | undefined;
  static currentOpenMenu: Element | undefined;
  static virtualElement: VirtualElement = {
    getBoundingClientRect: () =>
      Dropdown.currentOpenMenu?.getBoundingClientRect() ?? NULL_RECT,
  };
  menuContents: any;
  state: DropdownState = {
    open: false,
    selected: this.props.selected,
  };
  menuPlacement: 'bottom-start' | 'top-start' = 'bottom-start'; // RS Add: emote interface tweaks (Lira, February 2026)

  handleClick = () => {
    if (this.state.open) {
      this.setOpen(false);
    }
  };

  getDOMNode() {
    return findDOMFromVNode(this.$LI, true); // RS Edit: Inferno 7 to 9 (Lira, January 2026)
  }

  componentDidMount() {
    const domNode = this.getDOMNode();

    if (!domNode) {
      return;
    }
  }

  openMenu() {
    let renderedMenu = Dropdown.renderedMenu;
    if (renderedMenu === undefined) {
      renderedMenu = document.createElement('div');
      renderedMenu.className = DROPDOWN_DEFAULT_CLASSNAMES;
      document.body.appendChild(renderedMenu);
      Dropdown.renderedMenu = renderedMenu;
    }

    const domNode = this.getDOMNode()!;
    Dropdown.currentOpenMenu = domNode;

    renderedMenu.scrollTop = 0;
    renderedMenu.style.width =
      this.props.menuWidth ||
      // Hack, but domNode should *always* be the parent control meaning it will have width
      // @ts-ignore
      `${domNode.offsetWidth}px`;
    // RS Add Start: Improvements for emote interface (Lira, February 2026)
    const isRogueStarDropdown =
      this.props.dropdownStyle?.trim() === 'rogue-star';
    if (isRogueStarDropdown) {
      const triggerBounds = domNode.getBoundingClientRect();
      const availableBelow =
        window.innerHeight - triggerBounds.bottom - VIEWPORT_MENU_PADDING;
      const availableAbove = triggerBounds.top - VIEWPORT_MENU_PADDING;
      const shouldPlaceAbove =
        availableBelow < MIN_ROGUE_STAR_MENU_HEIGHT &&
        availableAbove > availableBelow;
      this.menuPlacement = shouldPlaceAbove ? 'top-start' : 'bottom-start';
      const availableSpace = shouldPlaceAbove ? availableAbove : availableBelow;
      renderedMenu.style.maxHeight = `${Math.max(1, Math.floor(availableSpace))}px`;
    } else {
      this.menuPlacement = 'bottom-start';
      renderedMenu.style.maxHeight = '';
    }
    // RS Add End
    renderedMenu.style.opacity = '1';
    renderedMenu.style.pointerEvents = 'auto';

    // ie hack
    // ie has this bizarre behavior where focus just silently fails if the
    // element being targeted "isn't ready"
    // 400 is probably way too high, but the lack of hotloading is testing my
    // patience on tuning it
    // I'm beyond giving a shit at this point it fucking works whatever
    setTimeout(() => {
      Dropdown.renderedMenu?.focus();
    }, 400);
    this.renderMenuContent();
  }

  closeMenu() {
    if (Dropdown.currentOpenMenu !== this.getDOMNode()) {
      return;
    }

    Dropdown.currentOpenMenu = undefined;
    Dropdown.renderedMenu!.style.opacity = '0';
    Dropdown.renderedMenu!.style.pointerEvents = 'none';
  }

  componentWillUnmount() {
    this.closeMenu();
    this.setOpen(false);
  }

  renderMenuContent() {
    const renderedMenu = Dropdown.renderedMenu;
    if (!renderedMenu) {
      return;
    }
    // RS Add Start: Improvements for emote interface (Lira, February 2026)
    const { dropdownStyle } = this.props;
    const menuStyleClass =
      dropdownStyle && `Dropdown__menu--${dropdownStyle.trim()}`;
    // RS Add End
    if (renderedMenu.offsetHeight > 200) {
      // RS Edit Start: Improvements for emote interface (Lira, February 2026)
      renderedMenu.className = classes([
        DROPDOWN_SCROLL_CLASSNAMES,
        menuStyleClass,
      ]);
      // RS Edit End
    } else {
      // RS Edit Start: Improvements for emote interface (Lira, February 2026)
      renderedMenu.className = classes([
        DROPDOWN_DEFAULT_CLASSNAMES,
        menuStyleClass,
      ]);
      // RS Edit End
    }

    const { options = [] } = this.props;
    const ops = options.map((option) => {
      let value, displayText;

      if (typeof option === 'string') {
        displayText = option;
        value = option;
      } else if (option !== null) {
        displayText = option.displayText;
        value = option.value;
      }

      return (
        <div
          key={value}
          className={classes([
            'Dropdown__menuentry',
            this.state.selected === value && 'selected',
          ])}
          onClick={() => {
            this.setSelected(value);
          }}>
          {displayText}
        </div>
      );
    });

    const to_render = ops.length ? ops : 'No Options Found';

    render(
      <div>{to_render}</div>,
      renderedMenu,
      () => {
        // RS Add Start: Improvements for emote interface (Lira, February 2026)
        const isRogueStarDropdown =
          this.props.dropdownStyle?.trim() === 'rogue-star';
        const popperModifiers: any[] = [...DEFAULT_OPTIONS.modifiers];
        if (isRogueStarDropdown) {
          popperModifiers.push({ name: 'flip', enabled: false });
          popperModifiers.push({ name: 'preventOverflow', enabled: false });
        }
        const popperOptions: Parameters<typeof createPopper>[2] = {
          ...DEFAULT_OPTIONS,
          placement: isRogueStarDropdown ? this.menuPlacement : 'bottom-start',
          modifiers: popperModifiers,
        };
        // RS Add End
        let singletonPopper = Dropdown.singletonPopper;
        if (singletonPopper === undefined) {
          singletonPopper = createPopper(
            Dropdown.virtualElement,
            renderedMenu!,
            popperOptions // RS Add: Improvements for emote interface (Lira, February 2026)
          );

          Dropdown.singletonPopper = singletonPopper;
        } else {
          singletonPopper.setOptions(popperOptions); // RS Edit: Improvements for emote interface (Lira, February 2026)

          singletonPopper.update();
        }
      },
      this.context
    );
  }

  setOpen(open: boolean) {
    this.setState((state) => ({
      ...state,
      open,
    }));
    if (open) {
      setTimeout(() => {
        this.openMenu();
        window.addEventListener('click', this.handleClick);
      });
    } else {
      this.closeMenu();
      window.removeEventListener('click', this.handleClick);
    }
  }

  setSelected(selected: string) {
    this.setState((state) => ({
      ...state,
      selected,
    }));
    this.setOpen(false);
    if (this.props.onSelected) {
      this.props.onSelected(selected);
    }
  }

  getOptionValue(option): string {
    return typeof option === 'string' ? option : option.value;
  }

  getSelectedIndex(): number {
    const selected = this.state.selected || this.props.selected;
    const { options = [] } = this.props;

    return options.findIndex((option) => {
      return this.getOptionValue(option) === selected;
    });
  }

  toPrevious(): void {
    if (this.props.options.length < 1) {
      return;
    }

    let selectedIndex = this.getSelectedIndex();
    const startIndex = 0;
    const endIndex = this.props.options.length - 1;

    const hasSelected = selectedIndex >= 0;
    if (!hasSelected) {
      selectedIndex = startIndex;
    }

    const previousIndex =
      selectedIndex === startIndex ? endIndex : selectedIndex - 1;

    this.setSelected(this.getOptionValue(this.props.options[previousIndex]));
  }

  toNext(): void {
    if (this.props.options.length < 1) {
      return;
    }

    let selectedIndex = this.getSelectedIndex();
    const startIndex = 0;
    const endIndex = this.props.options.length - 1;

    const hasSelected = selectedIndex >= 0;
    if (!hasSelected) {
      selectedIndex = endIndex;
    }

    const nextIndex =
      selectedIndex === endIndex ? startIndex : selectedIndex + 1;

    this.setSelected(this.getOptionValue(this.props.options[nextIndex]));
  }

  render() {
    const { props } = this;
    const {
      icon,
      iconRotation,
      iconSpin,
      clipSelectedText = true,
      color = 'default',
      dropdownStyle,
      over,
      nochevron,
      width,
      onClick,
      onSelected,
      selected,
      disabled,
      displayText,
      buttons,
      ...boxProps
    } = props;
    const { className, ...rest } = boxProps;

    const adjustedOpen = over ? !this.state.open : this.state.open;

    return (
      <Stack fill>
        <Stack.Item width={width}>
          <Box
            width={'100%'}
            className={classes([
              'Dropdown__control',
              'Button',
              'Button--color--' + color,
              disabled && 'Button--disabled',
              className,
            ])}
            onClick={(event) => {
              if (disabled && !this.state.open) {
                return;
              }
              this.setOpen(!this.state.open);
              if (onClick) {
                onClick(event);
              }
            }}
            {...rest}>
            {icon && (
              <Icon
                name={icon}
                rotation={iconRotation}
                spin={iconSpin}
                mr={1}
              />
            )}
            <span
              className="Dropdown__selected-text"
              style={{
                overflow: clipSelectedText ? 'hidden' : 'visible',
              }}>
              {displayText || this.state.selected}
            </span>
            {nochevron || (
              <span className="Dropdown__arrow-button">
                <Icon name={adjustedOpen ? 'chevron-up' : 'chevron-down'} />
              </span>
            )}
          </Box>
        </Stack.Item>
        {buttons && (
          <>
            <Stack.Item height={'100%'}>
              <Button
                height={'100%'}
                icon="chevron-left"
                disabled={disabled}
                onClick={() => {
                  if (disabled) {
                    return;
                  }

                  this.toPrevious();
                }}
              />
            </Stack.Item>
            <Stack.Item height={'100%'}>
              <Button
                height={'100%'}
                icon="chevron-right"
                disabled={disabled}
                onClick={() => {
                  if (disabled) {
                    return;
                  }

                  this.toNext();
                }}
              />
            </Stack.Item>
          </>
        )}
      </Stack>
    );
  }
}
