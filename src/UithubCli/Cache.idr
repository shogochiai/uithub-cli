module UithubCli.Cache

import System
import System.File
import System.Directory
import Data.String
import Data.List
import Data.List1

import UithubCli.Config

%default total

-- Parse "owner/repo" or "https://github.com/owner/repo" to (owner, repo)
export
parseRepoUrl : String -> Maybe (String, String)
parseRepoUrl url =
  let cleaned = if isPrefixOf "https://github.com/" url
                  then substr 19 (length url) url
                  else if isPrefixOf "http://github.com/" url
                    then substr 18 (length url) url
                    else if isPrefixOf "github.com/" url
                      then substr 11 (length url) url
                      else url
      parts = split (== '/') cleaned
  in case toList parts of
       (owner :: repo :: _) => Just (owner, trimTrailing repo)
       _ => Nothing
  where
    trimTrailing : String -> String
    trimTrailing s = pack $ takeWhile (\c => c /= '?' && c /= '#') (unpack s)

export
covering
repoCachePath : String -> String -> IO String
repoCachePath owner repo = do
  cache <- cacheDir
  pure $ cache ++ "/" ++ owner ++ "/" ++ repo

export
covering
ensureRepoCacheDir : String -> String -> IO (Either FileError ())
ensureRepoCacheDir owner repo = do
  cache <- cacheDir
  let repoDir = cache ++ "/" ++ owner ++ "/" ++ repo
  -- Use mkdir -p to handle all intermediate directories
  exitCode <- system $ "mkdir -p '" ++ repoDir ++ "'"
  pure $ if exitCode == 0 then Right () else Left FileNotFound

export
covering
getCachedContent : String -> String -> IO (Maybe String)
getCachedContent owner repo = do
  path <- repoCachePath owner repo
  let contentPath = path ++ "/content.md"
  Right content <- readFile contentPath
    | Left _ => pure Nothing
  pure (Just content)

export
covering
saveCachedContent : String -> String -> String -> IO (Either FileError ())
saveCachedContent owner repo content = do
  _ <- ensureRepoCacheDir owner repo
  path <- repoCachePath owner repo
  let contentPath = path ++ "/content.md"
  writeFile contentPath content

export
covering
listCachedRepos : IO (List (String, String))
listCachedRepos = do
  cache <- cacheDir
  Right owners <- listDir cache
    | Left _ => pure []
  repos <- traverse (getReposForOwner cache) owners
  pure $ concat repos
  where
    covering
    getReposForOwner : String -> String -> IO (List (String, String))
    getReposForOwner cache owner = do
      Right repos <- listDir (cache ++ "/" ++ owner)
        | Left _ => pure []
      pure $ map (\r => (owner, r)) repos
