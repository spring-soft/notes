export enum BreakpointType {
  SM = 0,
  MD = 1,
  LG = 2,
}

export interface WindowSize {
  width: number;
  height: number;
  breakpoint: BreakpointType;
}

export function calculateBreakpoint(widthVp: number): BreakpointType {
  if (widthVp < 600) {
    return BreakpointType.SM;
  }
  if (widthVp < 840) {
    return BreakpointType.MD;
  }
  return BreakpointType.LG;
}

export function isTablet(breakpoint: BreakpointType): boolean {
  return breakpoint === BreakpointType.MD || breakpoint === BreakpointType.LG;
}
