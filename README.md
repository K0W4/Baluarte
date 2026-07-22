# App DeMolay

> Aplicativo de gestão inteligente e gamificada para Capítulos da Ordem DeMolay.

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com)
[![Architecture](https://img.shields.io/badge/Architecture-MVVM-lightgrey.svg)]()
[![Design](https://img.shields.io/badge/Design-Heuristics%20%7C%20WCAG-blueviolet.svg)]()

## 📖 Visão Geral

O **App DeMolay** foi desenhado para revolucionar a gestão capitular, fornecendo ferramentas modernas e preditivas para o controle de presença (Roster), calendário de eventos, gestão financeira e engajamento dos membros através de um sistema de acompanhamento de metas.

O projeto foi construído focando em princípios de escalabilidade e design centrado no usuário, utilizando tecnologias de ponta do ecossistema Apple e mantendo uma arquitetura que permitirá uma expansão suave e futura para o Android.

## ✨ Principais Funcionalidades

* **🔒 Autenticação Robusta:** Login seguro e controle de permissões baseadas em cargos via Supabase.
* **📅 Calendário Inteligente:** Gestão visual de reuniões, rituais e eventos.
* **📊 Gestão de Metas:** Acompanhamento gamificado de objetivos (financeiros, iniciações, etc.) com cálculo automático de progressão.
* **📜 Roster (Lista de Presença):** Visão geral e controle de frequência de todos os membros ativos.
* **🤖 Inteligência Artificial (CoreML) - Em breve:** Leitura preditiva de documentos e atas utilizando Inteligência Artificial on-device.

## 🛠️ Stack Tecnológico e Arquitetura

O projeto segue estritamente o padrão **MVVM** (Model-View-ViewModel) utilizando o novo sistema de observação da Apple (iOS 17+).

* **Linguagem:** Swift
* **UI Framework:** SwiftUI
* **Design System:** Componentes e tokens padronizados e injetáveis. Desenvolvido com base em **Heurísticas de Nielsen**, **Acessibilidade WCAG**, e forte **Psicologia aplicada a UX**.
* **Gerenciamento de Estado:** `@Observable` (Substituindo o antigo `@ObservableObject`).
* **Injeção de Dependência:** Protocolos (Services) injetados via `@Environment`, permitindo testes isolados via Mocks.
* **Backend:** Supabase (PostgreSQL, PostgREST) configurado como BaaS.
* **Package Manager:** Swift Package Manager (SPM).

## 🚀 Como Começar (Getting Started)

### Pré-requisitos
* macOS Sonoma (14.0) ou superior.
* Xcode 15 ou superior.
* Conta ativa no Supabase (para o banco de dados).

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/YOUR_USERNAME/app-demolay.git
```

2. Abra o arquivo do projeto:
```bash
cd app-demolay
open "App DeMolay.xcodeproj"
```

3. O Swift Package Manager fará o download automático do SDK do Supabase.
4. Selecione o simulador desejado (ex: iPhone 15 Pro) e clique em **Run** (`Cmd + R`).

## 🗄️ Estrutura do Banco de Dados (Supabase)

A aplicação consome uma API gerada dinamicamente pelo Supabase, baseada no seguinte schema:

- `chapter`
- `member`
- `event`
- `goal` (Metas com porcentagem de progressão)
- `committee`

> **Nota de Segurança:** As tabelas utilizam RLS (Row Level Security) para garantir que os membros acessem apenas as informações relacionadas ao seu respectivo Capítulo. Os dados também são tratados para segurança máxima e criptografia local.

## 📐 Filosofia de Desenvolvimento e Design

Desenvolvido sob rígidos princípios de engenharia e design de produto:
- **KISS & YAGNI:** Priorização absoluta de soluções nativas do iOS (Minimum Viable Code). Nenhuma biblioteca de terceiros é utilizada a menos que seja estritamente necessária.
- **Test-Driven:** Arquitetura desacoplada via protocolos, pronta para testes unitários.
- **UX/UI Profundo:** Uso de micro-animações, contrastes semânticos, esqueletos de carregamento e tipografia fluida para gerar engajamento. As interfaces são desenhadas considerando a redução da carga cognitiva (Lei de Hick) e acessibilidade em primeiro plano.

## 📄 Licença

Este projeto é desenvolvido para uso interno por Capítulos da Ordem DeMolay. Todos os direitos reservados.
