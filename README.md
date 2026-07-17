# App DeMolay

> Aplicativo de gestão inteligente e gamificada para Capítulos da Ordem DeMolay.

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-lightgrey.svg)]()

## 📖 Visão Geral

O **App DeMolay** foi concebido para revolucionar a gestão de capítulos, fornecendo ferramentas modernas e preditivas para o controle de presença (Nominata), calendário de eventos, gestão financeira e engajamento dos membros através de um sistema de acompanhamento de metas.

O projeto foi construído focando nos princípios da escalabilidade, utilizando tecnologias de ponta do ecossistema Apple e mantendo uma arquitetura que permitirá uma futura e fluida expansão para Android.

## ✨ Funcionalidades Principais

* **🔒 Autenticação Robusta:** Login seguro e controle de permissões por cargo via Supabase.
* **📅 Calendário Inteligente:** Gerenciamento visual de reuniões, rituais e eventos.
* **📊 Gestão de Metas (Goals):** Acompanhamento gamificado de metas (financeiras, iniciações, etc) com cálculo automático de progressão.
* **📜 Nominata / Roster:** Visão geral e controle de presença de todos os membros ativos.
* **🤖 CoreML Integrado (Em breve):** Leitura preditiva de documentos e atas utilizando Inteligência Artificial local no dispositivo.

## 🛠️ Tecnologias e Arquitetura

Este projeto segue rigorosamente o padrão **MVVM** (Model-View-ViewModel) utilizando o novo sistema de observação da Apple (iOS 17+).

* **Linguagem:** Swift
* **Interface Gráfica:** SwiftUI
* **Design System:** Componentes e Tokens padronizados (Protocol-Oriented).
* **Gerenciamento de Estado:** `@Observable` (Substituindo o legado `@ObservableObject`).
* **Injeção de Dependência:** Protocolos (Services) injetados via `@Environment`, permitindo testes isolados via Mocks.
* **Backend:** Supabase (PostgreSQL, PostgREST) configurado como BaaS.
* **Package Manager:** Swift Package Manager (SPM).

## 🚀 Como Executar o Projeto

### Pré-requisitos
* macOS Sonoma (14.0) ou superior.
* Xcode 15 ou superior.
* Conta ativa no Supabase (para o banco de dados).

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/SEU_USUARIO/app-demolay.git
```

2. Abra o arquivo do projeto:
```bash
cd app-demolay
open "App DeMolay.xcodeproj"
```

3. O Swift Package Manager fará o download automático da SDK do Supabase.
4. Selecione o simulador desejado (iPhone 15 Pro, por exemplo) e clique em **Run** (`Cmd + R`).

## 🗄️ Estrutura do Banco de Dados (Supabase)

O aplicativo consome uma API gerada dinamicamente pelo Supabase, baseada no seguinte schema:

- `chapter` (Capítulos)
- `member` (Membros)
- `event` (Eventos)
- `goal` (Metas com porcentagem de progressão)
- `committee` (Comissões)

> **Nota de Segurança:** As tabelas utilizam RLS (Row Level Security) para garantir que membros acessem apenas as informações referentes ao seu respectivo Capítulo.

## 📐 Filosofia Ponytail (Design Principles)

Desenvolvido sob rigorosos princípios de engenharia:
- **KISS & YAGNI:** Priorização absoluta de soluções nativas do iOS (Minimum Viable Code). Nenhuma biblioteca de terceiros é utilizada a menos que estritamente necessária (ex: Supabase SDK).
- **Test-Driven:** Arquitetura desacoplada via protocolos, pronta para testes unitários.
- **Aesthetics First:** Utilização de micro-animações, contrastes semânticos e tipografia fluida para gerar engajamento através do Design de Interface.

## 📄 Licença

Este projeto é desenvolvido para uso interno de Capítulos da Ordem DeMolay. Todos os direitos reservados.
