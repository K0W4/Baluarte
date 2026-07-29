import SwiftUI

struct ChapterSelectionView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ChapterSelectionViewModel()
    @State private var showCreateChapter = false
    @State private var searchText = ""
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Encontre seu Capítulo")
                            .font(Typography.largeTitle)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Para aproveitar o Baluarte, você precisa estar vinculado a um Capítulo.")
                            .font(Typography.body)
                            .foregroundColor(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(Theme.accent)
                        Spacer()
                    } else if viewModel.chapters.isEmpty {
                        Spacer()
                        VStack(spacing: Spacing.md) {
                            Image(systemName: "building.2.crop.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .foregroundColor(Theme.accent)
                            
                            Text("Nenhum Capítulo encontrado")
                                .font(Typography.headline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                    } else {
                        List(viewModel.chapters) { chapter in
                            Button(action: {
                                Task {
                                    guard case let .authenticated(_, member) = authViewModel.state, let member = member else { return }
                                    _ = try? await viewModel.selectChapter(chapter, for: member)
                                    await authViewModel.checkSession() // Atualiza o estado
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(chapter.name)
                                            .font(Typography.headline)
                                            .foregroundColor(Theme.textPrimary)
                                        Text("Capítulo nº \(chapter.number)")
                                            .font(Typography.subheadline)
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .padding(.vertical, Spacing.xs)
                            }
                            .listRowBackground(Theme.backgroundSecondary)
                        }
                        .listStyle(.plain)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        showCreateChapter = true
                    }) {
                        Text("Criar Novo Capítulo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(Spacing.screenEdgePadding)
            }
        }
        .searchable(text: $searchText, prompt: "Buscar Capítulo")
        .onChange(of: searchText) { _, newValue in
            Task {
                await viewModel.searchChapters(query: newValue)
            }
        }
        .task {
            await viewModel.fetchChapters()
        }
        .sheet(isPresented: $showCreateChapter) {
            CreateChapterView {
                Task {
                    await viewModel.fetchChapters()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sair") {
                    showSignOutAlert = true
                }
                .foregroundColor(Theme.destructive)
            }
        }
        .alert("Deseja sair da conta?", isPresented: $showSignOutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Sair", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            }
        }
    }
}
