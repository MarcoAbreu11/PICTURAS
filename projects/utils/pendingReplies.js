// Pedidos a uma tool que esperam a resposta dentro do mesmo pedido HTTP (ex.: estimativa
// de tamanho da conversão). A resposta chega pela project_queue como as restantes; aqui
// associa-se ao pedido pelo correlationId. Fica em memória: há uma só instância do projects.
const pending = new Map();

class ReplyTimeoutError extends Error {}

function waitForReply(msgId, timeoutMs) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(msgId);
      reject(new ReplyTimeoutError(`No reply to ${msgId} after ${timeoutMs} ms`));
    }, timeoutMs);
    pending.set(msgId, { resolve, timer });
  });
}

// true se a mensagem era a resposta a um pedido pendente (e já foi entregue)
function settleReply(msgId, msgContent) {
  const entry = pending.get(msgId);
  if (!entry) return false;
  pending.delete(msgId);
  clearTimeout(entry.timer);
  entry.resolve(msgContent);
  return true;
}

module.exports = { waitForReply, settleReply, ReplyTimeoutError };
