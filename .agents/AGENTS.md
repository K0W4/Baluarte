# App DeMolay - Agent Rules

Estas regras guiam a geração de código para o App DeMolay, um aplicativo iOS nativo em SwiftUI para gestão de Capítulos da Ordem DeMolay. Todo código gerado deve seguir os mais altos padrões da Apple (Human Interface Guidelines, Paul Hudson, WWDC sessions), garantindo manutenibilidade, escalabilidade, segurança e testabilidade.

## 1. Estrutura de Pastas do Projeto

O projeto segue uma organização por responsabilidade. Novos arquivos devem ser criados nos diretórios corretos:

```
App DeMolay/
├── Core/               → Entry point (@main), Managers singleton (SupabaseManager, EventKitManager)
├── Models/             → Structs de dados (Codable, Identifiable, Hashable)
├── Views/              → Telas completas (cada aba do TabView e sub-telas)
├── ViewModels/         → Lógica de negócios (@Observable), 1 ViewModel por View principal
├── Services/           → Protocolos de serviço e suas implementações (Mock e Supabase)
├── DesignSystem/
│   ├── Theme.swift     → Paleta de cores semânticas
│   ├── Typography.swift → Escala tipográfica
│   ├── Spacing.swift   → Tokens de espaçamento
│   └── Components/
│       ├── Buttons/    → ButtonStyles reutilizáveis
│       └── Cards/      → Cards visuais (EventCard, MemberCard, etc.)
└── Assets.xcassets     → Ícones, cores e assets visuais
```

## 2. SwiftUI Best Practices (iOS 17+)

* **State Management**: Utilize estritamente a macro `@Observable` para ViewModels. Proibido usar `@ObservableObject` e `@Published` legados.
* **Navigation**: Utilize sempre `NavigationStack` com gerenciamento de rotas baseado em valor (ex: `enum Route: Hashable`), nunca `NavigationView`.
* **Dependency Injection**: Utilize `@Environment` para injetar dependências nas Views, favorecendo o desacoplamento.
* **Segurança e Estabilidade**: **NUNCA** utilize Force Unwrapping (`!`). Todas as propriedades opcionais devem ser tratadas com `if let`, `guard let` ou nil-coalescing (`??`).
* **Composição de UI**: Views com corpos grandes (`body`) devem ser quebradas em structs menores e reutilizáveis dentro de `DesignSystem/Components/`. Prefira criar sub-Views como structs separadas ao invés de funções que retornam `some View` dentro da própria struct.
* **Concorrência**: Utilize `async/await` e `Task {}` para chamadas assíncronas. Anotações `@MainActor` são obrigatórias em métodos de ViewModel que alteram estado da UI.

## 3. Arquitetura MVVM

* **Models**: Puramente declarativos. `struct` conformando com `Codable`, `Identifiable`, `Hashable`. Sem lógica de negócios. As `CodingKeys` devem mapear para `snake_case` do banco de dados.
* **Views**: Zero lógica de negócios. Interações de botões e ciclo de vida (`.task`, `.onAppear`) apenas chamam métodos da ViewModel. A View declara `@State private var viewModel = XxxViewModel()`.
* **ViewModels**: Contêm toda a lógica de negócios e preparação de dados. Devem ser testáveis isoladamente via injeção de dependências por protocolo.
* **Services (Protocol-Oriented)**: Toda comunicação com fontes de dados externas (Supabase, EventKit, CoreML) deve passar por um `protocol`. Cada protocolo possui uma implementação `Mock` (para desenvolvimento e testes) e uma implementação real (para produção). As ViewModels recebem o protocolo via `init`, com valor default para o Mock.

## 4. Design System

* Todas as cores devem vir de `Theme` (ex: `Theme.backgroundPrimary`, `Theme.textSecondary`). Proibido usar cores literais como `.gray` ou `Color(hex:)` diretamente nas Views.
* Toda tipografia deve vir de `Typography` (ex: `Typography.headline`, `Typography.caption1`). Proibido usar `.font(.system(size:))` diretamente.
* Todo espaçamento deve vir de `Spacing` (ex: `Spacing.md`, `Spacing.cardPadding`). Valores mágicos como `.padding(14)` são proibidos.
* Componentes visuais reutilizáveis (Cards, Botões, Rows) devem residir em `DesignSystem/Components/` e aceitar dados via parâmetros de `init`, nunca acessando ViewModels diretamente.

**Diretrizes Essenciais de UX/UI:** Todo novo layout ou refatoração visual deve **obrigatoriamente** levar em consideração:
- **Heurísticas de Nielsen:** Prevenção de erros, visibilidade do status do sistema, consistência e padrões.
- **WCAG Acessibilidade:** Contraste adequado de cores, tamanhos mínimos de toque (44x44pt) e suporte a VoiceOver/Dynamic Type.
- **Princípios de UX e Design:** Hierarquia visual clara, espaçamentos consistentes (Lei de Proximidade) e feedback visual imediato.
- **Psicologia aplicada UX:** Redução da carga cognitiva, Lei de Hick (poucas e boas opções) e Efeito Von Restorff (destaque para ações principais).

## 5. Testabilidade

* Todo código de ViewModel deve ser escrito visando testabilidade: dependências externas isoladas via protocolos, estado interno acessível publicamente para asserções, e métodos com responsabilidade única.
* Testes unitários cobrem exclusivamente a camada de ViewModels e Models (lógica de negócios, transformações de dados, filtros, computed properties).
* Mocks de serviços devem ser previsíveis e determinísticos para garantir resultados consistentes nos testes.

## 6. Filosofia de Código

* **YAGNI (You Ain't Gonna Need It)**: Não crie abstrações, genéricos ou features que não foram solicitadas no escopo atual da fase em andamento.
* **Prioridade Nativa**: Antes de sugerir qualquer dependência de terceiros (Swift Packages), esgote todas as possibilidades das APIs nativas do iOS/SwiftUI (EventKit, Foundation Models, AppIntents, WidgetKit, etc.).
* **Minimum Viable Code**: Produza a quantidade mínima de código necessária para resolver o problema com clareza e segurança. Evite over-engineering.
* **Sem Comentários no Código**: O código deve ser autoexplicativo através de nomes claros de variáveis, funções e tipos. Não utilize comentários inline (`//`), exceto para `MARK:` de organização em arquivos extensos.
* **Atualizações Otimistas**: Para operações de toggle ou atualização rápida na UI (ex: marcar tarefa como concluída), aplique a mudança visual imediatamente e reverta caso a API falhe.
