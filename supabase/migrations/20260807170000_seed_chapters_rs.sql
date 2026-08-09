-- Seed do catálogo: Capítulos do Rio Grande do Sul.
--
-- Relação fornecida pelo mantenedor do app a partir do registro da Ordem no RS:
-- 51 Capítulos, nome e número. A cidade não veio na relação e fica nula por ora --
-- inventar cidade a partir do nome seria chute, e a busca já cobre nome, número e UF.
-- Preencher depois é um simples UPDATE.
--
-- ON CONFLICT (uf, number) torna o arquivo idempotente: reaplicar atualiza o nome em
-- vez de duplicar. Esse é o ponto do catálogo curado -- um Capítulo tem uma linha só.

begin;

insert into public.chapter (id, name, number, uf, status) values
  (gen_random_uuid(), 'Santa Maria', 196, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros Templários do Vale do Taquari', 805, 'RS', 'active'),
  (gen_random_uuid(), 'Cachoeira', 821, 'RS', 'active'),
  (gen_random_uuid(), 'Santa Cruz', 902, 'RS', 'active'),
  (gen_random_uuid(), 'Venâncio Aires', 906, 'RS', 'active'),
  (gen_random_uuid(), 'São Pedro do Sul', 1268, 'RS', 'active'),
  (gen_random_uuid(), 'Porto Alegre', 46, 'RS', 'active'),
  (gen_random_uuid(), 'Mariano Fedele', 77, 'RS', 'active'),
  (gen_random_uuid(), 'Nobres Cavaleiros do Templo', 340, 'RS', 'active'),
  (gen_random_uuid(), 'Fênix II', 465, 'RS', 'active'),
  (gen_random_uuid(), 'Templários do Sul', 494, 'RS', 'active'),
  (gen_random_uuid(), 'Sentinela das Virtudes', 514, 'RS', 'active'),
  (gen_random_uuid(), 'Guardiões do Vale do Sinos', 592, 'RS', 'active'),
  (gen_random_uuid(), 'Capela Grande', 656, 'RS', 'active'),
  (gen_random_uuid(), 'Arquitetos do Oriente', 1030, 'RS', 'active'),
  (gen_random_uuid(), 'Guardiões das Torres', 451, 'RS', 'active'),
  (gen_random_uuid(), 'Escudeiros do Oriente', 493, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros do Sol', 630, 'RS', 'active'),
  (gen_random_uuid(), 'Caxias do Sul', 92, 'RS', 'active'),
  (gen_random_uuid(), 'Pérola das Colônias', 146, 'RS', 'active'),
  (gen_random_uuid(), 'Giuseppe Garibaldi', 597, 'RS', 'active'),
  (gen_random_uuid(), 'Farroupilha', 967, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros da Virtude', 1027, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros da Esperança', 1063, 'RS', 'active'),
  (gen_random_uuid(), 'Farrapos', 1111, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros dos Vinhedos', 1189, 'RS', 'active'),
  (gen_random_uuid(), 'União da Irmandade Altos da Serra', 1247, 'RS', 'active'),
  (gen_random_uuid(), 'Ijuí', 237, 'RS', 'active'),
  (gen_random_uuid(), 'Santo Ângelo', 306, 'RS', 'active'),
  (gen_random_uuid(), 'Cruz Alta', 382, 'RS', 'active'),
  (gen_random_uuid(), '14 de Julho', 580, 'RS', 'active'),
  (gen_random_uuid(), 'Guardiões do Horizonte', 853, 'RS', 'active'),
  (gen_random_uuid(), 'Passo Fundo', 243, 'RS', 'active'),
  (gen_random_uuid(), 'Garimpeiros das Virtudes', 635, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros da Fraternidade Real', 964, 'RS', 'active'),
  (gen_random_uuid(), 'Templários do Marau', 983, 'RS', 'active'),
  (gen_random_uuid(), 'Romeu Brum Ferreira', 1132, 'RS', 'active'),
  (gen_random_uuid(), 'Guardiões do Alto Uruguai', 1198, 'RS', 'active'),
  (gen_random_uuid(), 'Filhos de Hiram Abiff', 1209, 'RS', 'active'),
  (gen_random_uuid(), 'Construtores do Saber', 1250, 'RS', 'active'),
  (gen_random_uuid(), 'Pelotas', 3, 'RS', 'active'),
  (gen_random_uuid(), 'Rio Grande', 354, 'RS', 'active'),
  (gen_random_uuid(), 'Cavaleiros Farroupilhas', 858, 'RS', 'active'),
  (gen_random_uuid(), 'Uruguaiana', 95, 'RS', 'active'),
  (gen_random_uuid(), 'Alegrete', 384, 'RS', 'active'),
  (gen_random_uuid(), 'Cidade de São Borja', 575, 'RS', 'active'),
  (gen_random_uuid(), 'Ordem e Progresso Itaquiense', 1089, 'RS', 'active'),
  (gen_random_uuid(), 'Bagé', 91, 'RS', 'active'),
  (gen_random_uuid(), 'Santana do Livramento', 433, 'RS', 'active'),
  (gen_random_uuid(), 'Cruzeiro do Ponche Verde', 952, 'RS', 'active'),
  (gen_random_uuid(), 'Passo do Rosário', 1206, 'RS', 'active')
on conflict (uf, number) do update
  set name = excluded.name;

-- Os "Meu Capítulo" que sobreviverem à limpeza (porque têm membros ou eventos
-- ligados) saem da busca. Quem estiver vinculado a um deles continua usando o app
-- normalmente; ele só deixa de aparecer no catálogo, que agora é o registro oficial.
update public.chapter
   set status = 'pending_review'
 where name = 'Meu Capítulo';

commit;
