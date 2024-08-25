interface Document {
  /**
   * Strongly typed getElementById function that accepts
   * a generic T type. This allows you to specify
   * the type of element that you try to query without the need
   * of unsafe casts like 'as'.
   *
   * @example
   * ```typescript
   * const player = document.getElementById<HTMLVideoElement>('player');
   * ```
   */
  getElementById<T extends HTMLElement = HTMLElement>(elementId: string): T | undefined;
}

type a = typeof document.getElementById<HTMLAnchorElement>
