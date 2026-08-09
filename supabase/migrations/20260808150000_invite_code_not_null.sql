-- Restaura o NOT NULL de chapter_invite.code.
--
-- Ele foi derrubado por precaução ao trocar o DEFAULT pelo trigger, mas era zelo demais:
-- trigger BEFORE INSERT roda antes da checagem de constraint, então o código já está
-- preenchido quando o NOT NULL é avaliado. Um identificador único sem NOT NULL é uma
-- garantia perdida à toa.

begin;

update public.chapter_invite
   set code = public.generate_invite_code()
 where code is null;

alter table public.chapter_invite alter column code set not null;

commit;
