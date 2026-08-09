import Testing
import Foundation
@testable import Baluarte

@Suite("KeychainHelper Tests", .serialized)
struct KeychainHelperTests {
    
    let testService = "com.kowa.test.service"
    let testAccount = "testAccount"
    let testValue = "test_token_123"
    
    @Test("Save and Read Item")
    func testSaveAndRead() {
        // Arrange
        KeychainHelper.shared.delete(service: testService, account: testAccount) // Limpa antes do teste
        
        // Act
        KeychainHelper.shared.save(testValue, service: testService, account: testAccount)
        let readValue = KeychainHelper.shared.readString(service: testService, account: testAccount)
        
        // Assert
        #expect(readValue == testValue, "O valor lido deveria ser igual ao salvo")
        
        // Cleanup
        KeychainHelper.shared.delete(service: testService, account: testAccount)
    }
    
    @Test("Delete Item")
    func testDelete() {
        // Arrange
        KeychainHelper.shared.save(testValue, service: testService, account: testAccount)
        
        // Act
        KeychainHelper.shared.delete(service: testService, account: testAccount)
        let readValue = KeychainHelper.shared.readString(service: testService, account: testAccount)
        
        // Assert
        #expect(readValue == nil, "O valor lido deveria ser nil após ser deletado")
    }
    
    @Test("Read non-existent Item")
    func testReadNonExistent() {
        // Arrange
        KeychainHelper.shared.delete(service: testService, account: testAccount)
        
        // Act
        let readValue = KeychainHelper.shared.readString(service: testService, account: testAccount)
        
        // Assert
        #expect(readValue == nil, "O valor de uma chave inexistente deveria ser nil")
    }
}
