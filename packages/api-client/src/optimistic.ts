export async function optimisticAction({
  optimistic,
  rollback,
  action
}: {
  optimistic: () => void;
  rollback: () => void;
  action: () => Promise<any>;
}) {
  optimistic();
  try {
    const result = await action();
    if (result?.decision !== "allow") {
      rollback();
    }
    return result;
  } catch (e) {
    rollback();
    throw e;
  }
}
