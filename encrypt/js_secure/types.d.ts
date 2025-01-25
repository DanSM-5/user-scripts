// Polyfil missing type for Promise.withResolvers
interface PromiseConstructor {
  withResolvers: <T>() => {
    promise: Promise<T>;
    reject:  typeof Promise.reject<T>;
    resolve: typeof Promise.resolve<T>;
  }
}

