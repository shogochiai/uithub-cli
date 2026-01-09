module UithubCli.RepoList

import System
import System.File
import System.Directory
import Data.String
import Data.List

import UithubCli.Config

%default total

-- =============================================================================
-- uithub.toml Format (simple line-based):
--   # comment
--   owner/repo
--   another-owner/another-repo
-- =============================================================================

||| Trim whitespace from right
rtrimStr : String -> String
rtrimStr s = pack $ reverse $ dropWhile isSpace $ reverse $ unpack s

||| Trim whitespace from both sides
trimStr : String -> String
trimStr s = ltrim (rtrimStr s)

||| Parse repo list from file content
export
parseRepoList : String -> List String
parseRepoList content =
  let ls = lines content
      valid = filter isValidLine ls
  in map trimStr valid
  where
    isValidLine : String -> Bool
    isValidLine line =
      let trimmed = ltrim line
      in not (trimmed == "") && not (isPrefixOf "#" trimmed)

||| Serialize repo list to file content
export
serializeRepoList : List String -> String
serializeRepoList repos =
  unlines $ ["# uithub.toml - repos of interest", ""] ++ repos

-- =============================================================================
-- File Paths
-- =============================================================================

||| Global uithub.toml path (~/.uithub-cli/uithub.toml)
export
globalRepoListPath : IO String
globalRepoListPath = do
  dir <- configDir
  pure $ dir ++ "/uithub.toml"

||| Local uithub.toml path (current directory)
export
localRepoListPath : IO String
localRepoListPath = pure "uithub.toml"

-- =============================================================================
-- Read/Write Operations
-- =============================================================================

||| Read repo list from a file
export
covering
readRepoListFile : String -> IO (List String)
readRepoListFile path = do
  Right content <- readFile path
    | Left _ => pure []
  pure $ parseRepoList content

||| Read global repo list
export
covering
readGlobalRepoList : IO (List String)
readGlobalRepoList = do
  path <- globalRepoListPath
  readRepoListFile path

||| Read local repo list
export
covering
readLocalRepoList : IO (List String)
readLocalRepoList = do
  path <- localRepoListPath
  readRepoListFile path

||| Write repo list to a file
export
covering
writeRepoListFile : String -> List String -> IO (Either FileError ())
writeRepoListFile path repos = do
  let content = serializeRepoList repos
  writeFile path content

||| Add a repo to a list file (if not already present)
export
covering
addRepoToFile : String -> String -> IO (Either FileError ())
addRepoToFile path repo = do
  existing <- readRepoListFile path
  if elem repo existing
    then pure (Right ())  -- Already exists
    else writeRepoListFile path (existing ++ [repo])

||| Add repo to global list
export
covering
addRepoToGlobal : String -> IO (Either FileError ())
addRepoToGlobal repo = do
  _ <- ensureConfigDir
  path <- globalRepoListPath
  addRepoToFile path repo

||| Add repo to local list
export
covering
addRepoToLocal : String -> IO (Either FileError ())
addRepoToLocal repo = do
  path <- localRepoListPath
  addRepoToFile path repo
