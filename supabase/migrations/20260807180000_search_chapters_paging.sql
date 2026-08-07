-- O limite fixo de 50 resultados em search_chapters era baixo demais: só o Rio Grande
-- do Sul tem 51 Capítulos, então navegar por UF já cortava um. O teto vira parâmetro,
-- com um padrão que cobre a maior jurisdição do país com folga.
--
-- Ainda é uma página só, sem offset. Isso basta enquanto o catálogo é estadual; quando
-- virar nacional e alguém buscar sem filtro, vai precisar de paginação de verdade.

begin;

drop function if exists public.search_chapters(text, text);

create or replace function public.search_chapters(
  p_query text default null,
  p_uf    text default null,
  p_limit int  default 500
)
returns setof public.chapter language sql stable set search_path = '' as $$
  select c.*
    from public.chapter c
   where c.status <> 'pending_review'
     and (p_uf is null or p_uf = '' or c.uf = upper(p_uf))
     and (
       p_query is null or p_query = ''
       or c.search_text like '%' || public.immutable_unaccent(lower(p_query)) || '%'
     )
   order by c.uf nulls last, c.name
   limit least(greatest(coalesce(p_limit, 500), 1), 1000);
$$;

grant execute on function public.search_chapters(text, text, int) to anon, authenticated;

commit;
