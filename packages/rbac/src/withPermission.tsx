
export function withPermission(Component: any, perm: string) {
  return function Wrapped(props: any) {
    return <Component {...props} />;
  };
}
