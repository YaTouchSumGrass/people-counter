
export function toLocalTime(rfc3339) {
  const date = new Date(rfc3339);

  return date.toLocaleString(undefined, {
    year: "numeric",
    month: "long",
    day: "numeric",
    hour: "numeric",
    minute: "numeric",
    second: "numeric",
  });
}
