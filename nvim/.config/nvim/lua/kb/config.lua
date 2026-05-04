local M = {}

local function resolve_vault()
  if _G.KB_VAULT_OVERRIDE then
    return _G.KB_VAULT_OVERRIDE
  end
  local env = vim.env.KB_VAULT
  if env and env ~= "" then
    return env
  end
  return vim.fn.expand("~/Documents/ZettelkastenVault")
end

function M.vault()
  return resolve_vault()
end

function M.axis(name)
  if name == "all" then
    return M.vault()
  end
  return M.vault() .. "/" .. name
end

return M
