import Foundation
import Observation
import SwiftUI

public enum MembersFilter: String, CaseIterable, Identifiable {
    case todos = "Todos"
    case ativos = "Ativos"
    case seniors = "Sêniors"
    case macons = "Maçons"

    public var id: String { self.rawValue }
}

@MainActor
@Observable
public final class MembersViewModel {
    public var allMembers: [Member] = []
    public var searchText: String = ""
    public var selectedFilter: MembersFilter = .todos

    public var isLoading = false
    public var errorMessage: String?

    private let memberService: MemberServiceProtocol

    public init(memberService: MemberServiceProtocol = MockMemberService()) {
        self.memberService = memberService
    }

    public func loadMembers() async {
        isLoading = true
        errorMessage = nil
        do {
            let mockChapterId = UUID()
            allMembers = try await memberService.fetchMembers(for: mockChapterId)
        } catch {
            errorMessage = error.localizedDescription
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = false
        }
    }

    public var filteredMembers: [Member] {
        var result = allMembers

        switch selectedFilter {
        case .todos:
            break
        case .ativos:
            result = result.filter { $0.isActive }
        case .seniors:
            result = result.filter { $0.isSenior }
        case .macons:
            result = result.filter { $0.isMason }
        }

        if !searchText.isEmpty {
            result = result.filter { member in
                member.fullName.localizedCaseInsensitiveContains(searchText) ||
                (member.role?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        result.sort { $0.fullName < $1.fullName }

        return result
    }
}
