import { Dispatch, MutableRefObject, SetStateAction, useCallback, useRef, useState } from 'react';

export function useRefState<T = undefined>(): [ref: MutableRefObject<T | undefined>, setRef: Dispatch<SetStateAction<T | undefined>>];
export function useRefState<T>(initialValue: T): [ref: MutableRefObject<T>, setRef: Dispatch<SetStateAction<T>>];
export function useRefState<T>(initialValue?: T) {
  const ref = useRef(initialValue);
  const [, setState] = useState<T>(
    // Check if value passed is a function
    // if it is, pass a function that returns our initial value
    // otherwise useState will use it as a initializer function
    // rather than to store the reference to the function
    initialValue instanceof Function
      ? (() => initialValue as T)
      : initialValue as T
  );
  const setRef = useCallback<Dispatch<SetStateAction<T>>>((setRefArg) => {
    if (setRefArg instanceof Function) {
      setState(prev => {
        const newValue = setRefArg(prev);
        ref.current = newValue;

        return newValue;
      });
      return;
    }

    ref.current = setRefArg;
    setState(setRefArg);
  }, []);

  return [ref, setRef];
}
