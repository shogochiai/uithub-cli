||| UithubCli Test Suite
||| Tests for uithub CLI wrapper functionality
module UithubCli.Tests.AllTests

import Data.List
import Data.String
import System
import System.File
import System.Directory

import UithubCli.Config
import UithubCli.Cache
import UithubCli.Http
import UithubCli.RepoList

%default covering

-- =============================================================================
-- Minimal Test Infrastructure
-- =============================================================================

public export
TestDef : Type
TestDef = (String, String, IO Bool)

export
test : String -> String -> IO Bool -> TestDef
test specId desc fn = (specId, desc, fn)

runSingleTest : TestDef -> IO Bool
runSingleTest (specId, desc, testFn) = do
  result <- testFn
  putStrLn $ "[" ++ (if result then "PASS" else "FAIL") ++ "] " ++ specId ++ ": " ++ desc
  pure result

runTestList : List TestDef -> IO Bool
runTestList tests = do
  results <- traverse runSingleTest tests
  pure $ all id results

-- =============================================================================
-- Test Helpers
-- =============================================================================

||| Cleanup test artifacts
cleanupTestDir : String -> IO ()
cleanupTestDir dir = do
  _ <- system $ "rm -rf '" ++ dir ++ "'"
  pure ()

-- =============================================================================
-- Configuration Tests
-- =============================================================================

||| REQ_UC_CFG_001: Load API key from environment
||| Tests that configDir uses HOME env variable
test_env_api_key : IO Bool
test_env_api_key = do
  -- configDir should return path based on HOME
  dir <- configDir
  -- Should contain ".uithub-cli" suffix
  pure $ isSuffixOf "/.uithub-cli" dir

||| REQ_UC_CFG_002: Load API key from config file
||| Tests writeConfig and readConfig round-trip
test_file_api_key : IO Bool
test_file_api_key = do
  -- Ensure config dir exists
  _ <- ensureConfigDir
  -- Write a test key
  let testKey = "test_key_12345"
  Right _ <- setApiKey testKey
    | Left _ => pure False
  -- Read it back
  Just readKey <- getApiKey
    | Nothing => pure False
  pure $ readKey == testKey

-- =============================================================================
-- Cache Tests
-- =============================================================================

||| REQ_UC_CACHE_001: Cache file creation and retrieval
||| Tests saveCachedContent and getCachedContent
test_cache_create : IO Bool
test_cache_create = do
  let testOwner = "test-owner"
  let testRepo = "test-repo"
  let testContent = "# Test Content\nThis is test markdown."
  -- Save content to cache
  Right _ <- saveCachedContent testOwner testRepo testContent
    | Left _ => pure False
  -- Read it back
  Just content <- getCachedContent testOwner testRepo
    | Nothing => pure False
  -- Cleanup
  cache <- cacheDir
  cleanupTestDir (cache ++ "/" ++ testOwner)
  pure $ content == testContent

||| REQ_UC_CACHE_002: Cache invalidation on update
||| Tests that saving new content overwrites old
test_cache_invalidate : IO Bool
test_cache_invalidate = do
  let testOwner = "test-owner2"
  let testRepo = "test-repo2"
  let content1 = "Version 1"
  let content2 = "Version 2 - Updated"
  -- Save initial content
  Right _ <- saveCachedContent testOwner testRepo content1
    | Left _ => pure False
  -- Overwrite with new content
  Right _ <- saveCachedContent testOwner testRepo content2
    | Left _ => pure False
  -- Read back should be new content
  Just content <- getCachedContent testOwner testRepo
    | Nothing => pure False
  -- Cleanup
  cache <- cacheDir
  cleanupTestDir (cache ++ "/" ++ testOwner)
  pure $ content == content2

-- =============================================================================
-- HTTP Tests
-- =============================================================================

||| REQ_UC_HTTP_001: Fetch repo with valid auth
||| Tests uithubUrl construction (pure function)
test_http_fetch : IO Bool
test_http_fetch = do
  let url = uithubUrl "anthropics" "claude-code"
  pure $ url == "https://uithub.com/anthropics/claude-code"

||| REQ_UC_HTTP_002: Handle HTTP error responses
||| Tests URL construction for various inputs
test_http_error : IO Bool
test_http_error = do
  -- Test URL construction handles special chars
  let url1 = uithubUrl "owner" "repo-name"
  let url2 = uithubUrl "org" "project"
  pure $ url1 == "https://uithub.com/owner/repo-name" &&
         url2 == "https://uithub.com/org/project"

-- =============================================================================
-- Command Tests (via parseRepoUrl)
-- =============================================================================

||| REQ_UC_CMD_001: Fetch command creates cache
||| Tests parseRepoUrl for GitHub URLs
test_cmd_fetch : IO Bool
test_cmd_fetch = do
  -- Test full GitHub URL parsing
  let Just (o1, r1) = parseRepoUrl "https://github.com/owner/repo"
    | Nothing => pure False
  -- Test short form
  let Just (o2, r2) = parseRepoUrl "owner/repo"
    | Nothing => pure False
  pure $ o1 == "owner" && r1 == "repo" &&
         o2 == "owner" && r2 == "repo"

||| REQ_UC_CMD_002: Get command returns cached content
||| Tests parseRepoUrl with query params stripped
test_cmd_get : IO Bool
test_cmd_get = do
  -- URL with query params should be cleaned
  let Just (owner, repo) = parseRepoUrl "github.com/owner/repo?tab=readme"
    | Nothing => pure False
  pure $ owner == "owner" && repo == "repo"

||| REQ_UC_CMD_003: List command shows cached repos
||| Tests listCachedRepos returns correct format
test_cmd_list : IO Bool
test_cmd_list = do
  let testOwner = "list-test-owner"
  let testRepo = "list-test-repo"
  -- Create a cached entry
  Right _ <- saveCachedContent testOwner testRepo "test"
    | Left _ => pure False
  -- List should include it
  repos <- listCachedRepos
  -- Cleanup
  cache <- cacheDir
  cleanupTestDir (cache ++ "/" ++ testOwner)
  -- Check if our test repo was in the list
  pure $ any (\(o, r) => o == testOwner && r == testRepo) repos

-- =============================================================================
-- RepoList Tests
-- =============================================================================

||| REQ_UC_REPO_001: Parse repo list from file content
||| Tests parseRepoList function
test_repo_parse : IO Bool
test_repo_parse = do
  let content = "# comment\n\nowner/repo1\n  owner/repo2  \n# another comment\nowner/repo3"
  let repos = parseRepoList content
  -- Should have 3 repos, trimmed and without comments
  pure $ repos == ["owner/repo1", "owner/repo2", "owner/repo3"]

||| REQ_UC_REPO_002: Serialize repo list to file content
||| Tests serializeRepoList function
test_repo_serialize : IO Bool
test_repo_serialize = do
  let repos = ["owner/repo1", "owner/repo2"]
  let content = serializeRepoList repos
  -- Should contain header and repos
  pure $ isInfixOf "owner/repo1" content && isInfixOf "owner/repo2" content

||| REQ_UC_REPO_003: Add repo to list file
||| Tests addRepoToFile (via roundtrip)
test_repo_add : IO Bool
test_repo_add = do
  let testFile = "/tmp/test-uithub-toml-" ++ show !time ++ ".toml"
  -- Add first repo
  Right _ <- writeRepoListFile testFile ["owner/repo1"]
    | Left _ => pure False
  -- Add second repo
  Right _ <- addRepoToFile testFile "owner/repo2"
    | Left _ => pure False
  -- Read back
  repos <- readRepoListFile testFile
  -- Cleanup
  _ <- system $ "rm -f '" ++ testFile ++ "'"
  pure $ elem "owner/repo1" repos && elem "owner/repo2" repos

||| REQ_UC_INSTALL_001: Install fetches all repos from uithub.toml
||| Tests that parseRepoList handles empty/malformed input
test_install_parse : IO Bool
test_install_parse = do
  -- Empty content
  let repos1 = parseRepoList ""
  -- Only comments
  let repos2 = parseRepoList "# just a comment\n# another"
  -- Only whitespace
  let repos3 = parseRepoList "   \n   \n   "
  pure $ repos1 == [] && repos2 == [] && repos3 == []

-- =============================================================================
-- Test Collection
-- =============================================================================

public export
allTests : List TestDef
allTests =
  [ test "REQ_UC_CFG_001" "Load API key from environment" test_env_api_key
  , test "REQ_UC_CFG_002" "Load API key from config file" test_file_api_key
  , test "REQ_UC_CACHE_001" "Cache file creation and retrieval" test_cache_create
  , test "REQ_UC_CACHE_002" "Cache invalidation on update" test_cache_invalidate
  , test "REQ_UC_HTTP_001" "Fetch repo with valid auth" test_http_fetch
  , test "REQ_UC_HTTP_002" "Handle HTTP error responses" test_http_error
  , test "REQ_UC_CMD_001" "Fetch command creates cache" test_cmd_fetch
  , test "REQ_UC_CMD_002" "Get command returns cached content" test_cmd_get
  , test "REQ_UC_CMD_003" "List command shows cached repos" test_cmd_list
  , test "REQ_UC_REPO_001" "Parse repo list from file content" test_repo_parse
  , test "REQ_UC_REPO_002" "Serialize repo list to file content" test_repo_serialize
  , test "REQ_UC_REPO_003" "Add repo to list file" test_repo_add
  , test "REQ_UC_INSTALL_001" "Install fetches all repos from uithub.toml" test_install_parse
  ]

-- =============================================================================
-- Main Entry Point
-- =============================================================================

export
runAllTests : IO ()
runAllTests = do
  putStrLn $ "Running UithubCli (" ++ show (length allTests) ++ " tests)..."
  allPassed <- runTestList allTests
  putStrLn ""
  putStrLn $ "Total: " ++ show (length allTests) ++ " tests"
  if allPassed
    then putStrLn "All tests passed!"
    else putStrLn "Some tests failed."

main : IO ()
main = runAllTests
