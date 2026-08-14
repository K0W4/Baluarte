-- `uf` faz parte da chave de um Capítulo, então não pode ser nulo.
--
-- A numeração de Capítulo no Brasil é por jurisdição estadual, e o registro já diz isso:
-- `chapter_uf_number_key unique nulls not distinct (uf, number)`. O `nulls not distinct`
-- impede dois Capítulos sem UF com o mesmo número -- mas **não** impede um com UF e outro
-- sem, porque 'RS' e NULL são valores diferentes.
--
-- Foi exatamente o que aconteceu com o 656: um Capítulo criado à mão antes do registro
-- existir, sem UF, e depois o seed do RS inserindo o oficial. Os dois coexistiram por
-- semanas. O da vida real -- 4 eventos, 3 comissões, o vínculo -- era o **sem** UF, e por
-- isso a tela do Capítulo mostrava "Capítulo nº 656" sem jurisdição nenhuma: o dado não
-- estava lá para ser mostrado.
--
-- O que fecha o buraco não é outra unique: é `uf` deixar de aceitar nulo. Com a coluna
-- obrigatória, `(uf, number)` volta a ser uma chave de verdade e o par duplicado deixa de
-- ser representável. `chapter_request.uf` já era `not null` desde sempre, então quem entra
-- pelo caminho normal nunca produziu o problema -- ele só existia para linha escrita à mão.

begin;

-- Abortar com a lista, e não com "violates not-null constraint" numa linha anônima.
-- Quem rodar isto e falhar precisa saber *quais* Capítulos preencher.
do $$
declare faltando bigint;
begin
  select count(*) into faltando from public.chapter where uf is null;
  if faltando > 0 then
    raise exception
      'Há % Capítulo(s) sem uf. Preencha antes de aplicar: select id, name, number from public.chapter where uf is null;',
      faltando;
  end if;
end $$;

alter table public.chapter alter column uf set not null;

commit;
