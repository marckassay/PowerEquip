using module ..\.\TestRunnerSupportModule.psm1

Describe "Test Invoke-TestSuiteRunner" {
    BeforeAll {
        $TestSupportModule = [TestRunnerSupportModule]::new('MockModuleB')
    }
    
    AfterAll {
        $TestSupportModule.Teardown()
    }
    
    Context "Call Invoke-TestSuiteRunner with request 'Path' value" {

        It "Should of called Start-Job which in-turn calls Invoke-Pester" {

            Mock Start-Job {} -ModuleName PowerBolt

            Invoke-TestSuiteRunner -Path ($TestSupportModule.MockDirectoryPath)
            
            Assert-MockCalled Start-Job -ParameterFilter {
                $Name -eq "JobPester"
            } -ModuleName PowerBolt -Times 1
            
            Assert-MockCalled Start-Job -ParameterFilter {
                $ArgumentList[0].Script -like '*io*'
            } -ModuleName PowerBolt -Times 1
        }
    }
}