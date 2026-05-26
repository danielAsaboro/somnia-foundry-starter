export type AgentRole = "Requester" | "Auditor";

export interface AgentLog {
  timestamp: string;
  role: AgentRole;
  action: string;
  requestId?: string;
  txHash?: string;
  status: "planned" | "sent" | "confirmed" | "pending" | "complete" | "failed";
  message: string;
  data?: unknown;
}

export function logAgent(event: AgentLog): void {
  console.log(
    JSON.stringify(event, (_key, value) =>
      typeof value === "bigint" ? value.toString() : value,
    ),
  );
}

export function nowIso(): string {
  return new Date().toISOString();
}
