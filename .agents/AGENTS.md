# App DeMolay - Agent Rules

Estas regras foram estabelecidas para guiar a IA na geração de código com os mais altos padrões do mercado (inspirado por Paul Hudson e guidelines da Apple), garantindo manutenibilidade, escalabilidade e testes.

## 1. SwiftUI Best Practices (iOS 17+)
* **State Management**: Utilize estritamente a nova macro `@Observable` para ViewModels. Proibido usar `@ObservableObject` e `@Published` legados.
* **Navigation**: Utilize sempre `NavigationStack` com gerenciamento de rotas baseado em valor (ex: `enum Route: Hashable`), e não o obsoleto `NavigationView` ou múltiplos `NavigationLink` isolados.
* **Dependency Injection**: Utilize `@Environment` para injetar dependências nas Views, favorecendo o desacoplamento.
* **Segurança e Estabilidade**: **NUNCA** utilize Force Unwrapping (`!`). Todas as propriedades opcionais devem ser tratadas com `if let`, `guard let` ou nil-coalescing (`??`).
* **Composição de UI**: Views com corpos grandes (`body`) devem ser quebradas em structs menores e reutilizáveis (no `DesignSystem/Components`). Evite criar funções que retornam `some View` dentro da própria struct, prefira criar sub-Views separadas.

## 2. Arquitetura Orientada a MVVM
* **Models**: Devem ser puramente declarativos (`struct`, conformando com `Codable`, `Identifiable`, `Hashable`). 
* **Views**: Não devem conter nenhuma lógica de negócios. Interações de botões ou ciclo de vida devem simplesmente chamar os métodos apropriados da `ViewModel`.
* **ViewModels**: Devem conter toda a lógica de negócios e preparação de dados. Devem ser testáveis isoladamente.
* **Protocol-Oriented**: Quando prepararmos os serviços (Supabase/AI), eles devem ser implementados por trás de protocolos (`protocol`) para que a ViewModel receba uma versão *Mock* durante os testes ou na Semana 1.

## 3. Design System
* Utilize os componentes centralizados (Cores do `Color.Theme`, tipografia do `Typography.swift`). 
* Valores mágicos (ex: `.padding(14)`) devem ser evitados em favor de abstrações ou espaçamentos consistentes.

## 4. TDD (Test-Driven Development)
* O código das ViewModels deve ser escrito pensando na sua testabilidade (isolamento de dependências externas). Na Semana 3, a injeção de dependência via protocolo permitirá a criação de *Unit Tests* perfeitos.

## 5. Filosofia Ponytail (YAGNI & Minimalism)
* **Mindset Sênior Preguiçoso**: O melhor código é aquele que não precisa ser escrito. Sempre busque a solução mais simples possível.
* **YAGNI (You Ain't Gonna Need It)**: Não crie abstrações complexas, genéricas ou features que não foram estritamente solicitadas no escopo atual.
* **Prioridade Nativa**: Antes de sugerir qualquer biblioteca de terceiros (Swift Packages), esgote todas as possibilidades das APIs nativas do iOS/SwiftUI.
* **Minimum Viable Code**: Ao gerar código, produza a quantidade mínima absoluta necessária para resolver o problema com clareza e segurança, evitando *over-engineering* e inchaço do projeto (*code bloat*).
