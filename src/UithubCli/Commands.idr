module UithubCli.Commands

import System
import System.File
import Data.String
import Data.List

import UithubCli.Config
import UithubCli.Cache
import UithubCli.Http
import UithubCli.RepoList

%default total

covering
withApiKey : (String -> IO ()) -> IO ()
withApiKey action = do
  Just key <- getApiKey
    | Nothing => do
        putStrLn "Error: API key not configured"
        putStrLn "Run: uithub-cli config set-key <your-api-key>"
  action key

covering
fetchAndCache : String -> String -> String -> IO ()
fetchAndCache key owner repo = do
  putStrLn $ "Fetching " ++ owner ++ "/" ++ repo ++ "..."
  Right content <- fetchUithub key owner repo
    | Left err => putStrLn $ "Error: " ++ err
  Right _ <- saveCachedContent owner repo content
    | Left _ => putStrLn "Error saving cache"
  putStrLn $ "Cached " ++ owner ++ "/" ++ repo ++ " (" ++ show (length content) ++ " bytes)"

export
covering
cmdFetch : String -> IO ()
cmdFetch url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  withApiKey $ \key => fetchAndCache key owner repo

export
covering
cmdGet : String -> IO ()
cmdGet url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  Just content <- getCachedContent owner repo
    | Nothing => do
        putStrLn $ "Not cached, fetching..."
        withApiKey $ \key => fetchAndCache key owner repo
  putStr content

export
covering
cmdUpdate : String -> IO ()
cmdUpdate url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  withApiKey $ \key => fetchAndCache key owner repo

export
covering
cmdList : IO ()
cmdList = do
  repos <- listCachedRepos
  case repos of
    [] => putStrLn "No cached repositories"
    _ => do
      putStrLn "Cached repositories:"
      traverse_ (\(o, r) => putStrLn $ "  " ++ o ++ "/" ++ r) repos

export
covering
cmdSetKey : String -> IO ()
cmdSetKey key = do
  Right _ <- setApiKey key
    | Left _ => putStrLn "Error saving API key"
  putStrLn "API key saved"

export
covering
cmdShowConfig : IO ()
cmdShowConfig = do
  cfg <- readConfig
  case cfg.apiKey of
    Just key => putStrLn $ "API Key: " ++ substr 0 10 key ++ "...(hidden)"
    Nothing => putStrLn "API Key: not set"

-- =============================================================================
-- Fetch with save options
-- =============================================================================

||| Fetch options
public export
record FetchOpts where
  constructor MkFetchOpts
  saveLocal : Bool   -- --save / -s
  saveGlobal : Bool  -- --global / -g

export
defaultFetchOpts : FetchOpts
defaultFetchOpts = MkFetchOpts False False

||| Fetch with options to save to uithub.toml
export
covering
cmdFetchWithOpts : FetchOpts -> String -> IO ()
cmdFetchWithOpts opts url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  let repoStr = owner ++ "/" ++ repo
  -- Fetch the content
  withApiKey $ \key => fetchAndCache key owner repo
  -- Save to local uithub.toml if --save
  when opts.saveLocal $ do
    Right _ <- addRepoToLocal repoStr
      | Left _ => putStrLn "Warning: Failed to save to local uithub.toml"
    putStrLn $ "Added to ./uithub.toml"
  -- Save to global uithub.toml if --global
  when opts.saveGlobal $ do
    Right _ <- addRepoToGlobal repoStr
      | Left _ => putStrLn "Warning: Failed to save to global uithub.toml"
    putStrLn $ "Added to global uithub.toml"

-- =============================================================================
-- Install command (fetch all from uithub.toml)
-- =============================================================================

||| Install options
public export
record InstallOpts where
  constructor MkInstallOpts
  useGlobal : Bool  -- Use global instead of local

export
defaultInstallOpts : InstallOpts
defaultInstallOpts = MkInstallOpts False

covering
installRepo : String -> String -> IO ()
installRepo key repoStr = do
  Just (owner, repo) <- pure $ parseRepoUrl repoStr
    | Nothing => putStrLn $ "  Skipping invalid: " ++ repoStr
  fetchAndCache key owner repo

||| Install all repos from uithub.toml
export
covering
cmdInstall : InstallOpts -> IO ()
cmdInstall opts = do
  -- Read repo list
  repos <- if opts.useGlobal
             then readGlobalRepoList
             else readLocalRepoList
  let source = if opts.useGlobal then "global" else "local"
  case repos of
    [] => putStrLn $ "No repos in " ++ source ++ " uithub.toml"
    _ => do
      putStrLn $ "Installing " ++ show (length repos) ++ " repos from " ++ source ++ " uithub.toml..."
      withApiKey $ \key => traverse_ (installRepo key) repos
      putStrLn "Done."

-- =============================================================================
-- Show repo list
-- =============================================================================

||| Show repos in uithub.toml
export
covering
cmdShowRepos : Bool -> IO ()
cmdShowRepos useGlobal = do
  repos <- if useGlobal then readGlobalRepoList else readLocalRepoList
  let source = if useGlobal then "global" else "local"
  case (the (List String) repos) of
    [] => putStrLn $ "No repos in " ++ source ++ " uithub.toml"
    rs => do
      putStrLn $ source ++ " uithub.toml:"
      traverse_ (\r => putStrLn $ "  " ++ r) rs
