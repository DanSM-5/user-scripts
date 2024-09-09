import {
  Dispatch,
  MutableRefObject,
  SetStateAction,
  useCallback,
  useRef,
  useState,
} from 'react';

export function useStateRef<T = undefined>(): [
  state: T | undefined,
  setState: Dispatch<SetStateAction<T | undefined>>,
  ref: Readonly<MutableRefObject<T | undefined>>,
];
export function useStateRef<T>(
  initialValue: T
): [
    state: T,
    setState: Dispatch<SetStateAction<T>>,
    ref: Readonly<MutableRefObject<T>>,
  ];
export function useStateRef<T>(initialValue?: T) {
  const [state, setState] = useState<T>(
    // Check if value passed is a function
    // if it is, pass a function that returns our initial value
    // otherwise useState will use it as a initializer function
    // rather than to store the reference to the function
    initialValue instanceof Function
      ? () => initialValue as T
      : (initialValue as T)
  );
  const ref = useRef(state);
  // Sync on each reander
  ref.current = state;

  const setStateRef = useCallback<Dispatch<SetStateAction<T>>>((setRefArg) => {
    if (setRefArg instanceof Function) {
      setState((prev) => {
        const newValue = setRefArg(prev);
        ref.current = newValue;

        return newValue;
      });
      return;
    }

    ref.current = setRefArg;
    setState(setRefArg);
  }, []);

  return [state, setStateRef, ref as Readonly<typeof ref>];
}
