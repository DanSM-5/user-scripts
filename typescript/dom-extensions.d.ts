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

/**
 * Type polyfill for Promise.withResolvers function
 * Ref: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/withResolvers
 */
interface PromiseConstructor {
  withResolvers: <T>() => {
    promise: Promise<T>;
    reject:  typeof Promise.reject<T>;
    resolve: typeof Promise.resolve<T>;
  }
}

/**
 * Type polyfill for {ErrorConstructor} to accept an object with an optional cause property
 * Ref: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/Error#options
 */
interface ErrorConstructor {
  new (message?: string, options?: { cause?: unknown })
}

