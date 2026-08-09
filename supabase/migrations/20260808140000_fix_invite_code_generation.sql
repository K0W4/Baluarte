-- Corrige a criação de convites, que falhava para todo mundo.
--
-- O código saía de um DEFAULT na coluna chamando generate_invite_code(), e o EXECUTE
-- dessa função tinha sido revogado de `authenticated` para o cliente não poder chamá-la
-- direto. Só que expressão de DEFAULT é avaliada com o privilégio de quem insere --
-- então o próprio INSERT batia em "permission denied for function", tanto para admin
-- quanto para fundador.
--
-- A saída é um trigger BEFORE INSERT em vez de um DEFAULT: o privilégio de EXECUTE é
-- conferido quando o trigger é criado, não a cada disparo, então o código continua
-- gerado no servidor e o cliente segue sem conseguir chamar a função.

begin;

alter table public.chapter_invite alter column code drop default;
alter table public.chapter_invite alter column code drop not null;

create or replace function public.set_invite_code()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Ignora qualquer valor que tenha vindo do cliente: o código é do servidor.
  new.code := public.generate_invite_code();
  return new;
end $$;

drop trigger if exists chapter_invite_set_code on public.chapter_invite;
create trigger chapter_invite_set_code
  before insert on public.chapter_invite
  for each row execute function public.set_invite_code();

commit;
