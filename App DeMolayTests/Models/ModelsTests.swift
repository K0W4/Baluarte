import Testing
import Foundation
@testable import App_DeMolay

@Suite("Models Tests")
struct ModelsTests {
    
    @Test("Event JSON Parsing maps CodingKeys correctly")
    func testEventDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "chapter_id": "123e4567-e89b-12d3-a456-426614174001",
            "title": "Reunião Especial",
            "scheduled_date": "2024-12-01T20:00:00Z",
            "event_type": "Reunião",
            "notes": "Traje completo",
            "confirmed_attendees": ["123e4567-e89b-12d3-a456-426614174002"],
            "created_at": "2024-11-01T10:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let event = try decoder.decode(Event.self, from: data)
        
        #expect(event.id.uuidString == "123E4567-E89B-12D3-A456-426614174000")
        #expect(event.chapterId.uuidString == "123E4567-E89B-12D3-A456-426614174001")
        #expect(event.title == "Reunião Especial")
        #expect(event.eventType == "Reunião")
        #expect(event.notes == "Traje completo")
        #expect(event.confirmedAttendees?.first?.uuidString == "123E4567-E89B-12D3-A456-426614174002")
    }
    
    @Test("Goal JSON Parsing maps CodingKeys correctly")
    func testGoalDecoding() throws {
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "chapter_id": "123e4567-e89b-12d3-a456-426614174001",
            "title": "Meta 1",
            "is_completed": false,
            "current_value": 10.5,
            "target_value": 20.0,
            "target_date": "2024-12-01T20:00:00Z",
            "created_at": "2024-11-01T10:00:00Z"
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let goal = try decoder.decode(Goal.self, from: data)
        #expect(goal.title == "Meta 1")
        #expect(goal.currentValue == 10.5)
        #expect(goal.targetValue == 20.0)
    }
}
