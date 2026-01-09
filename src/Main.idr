module Main

import System
import System.File
import System.Directory
import Data.String
import Data.List

import UithubCli.Config
import UithubCli.Cache
import UithubCli.Http
import UithubCli.Commands

%default total

printUsage : IO ()
printUsage = do
  putStrLn "uithub-cli - Fetch GitHub repos as LLM-friendly markdown"
  putStrLn ""
  putStrLn "Usage:"
  putStrLn "  uithub-cli fetch [opts] <repo>  Fetch and cache repository"
  putStrLn "    -s, --save                    Save to ./uithub.toml"
  putStrLn "    -g, --global                  Save to global uithub.toml"
  putStrLn ""
  putStrLn "  uithub-cli get <repo>           Get from cache (fetch if missing)"
  putStrLn "  uithub-cli update <repo>        Force re-fetch"
  putStrLn "  uithub-cli list                 List cached repositories"
  putStrLn ""
  putStrLn "  uithub-cli install [opts]       Fetch all repos from uithub.toml"
  putStrLn "    -g, --global                  Use global uithub.toml"
  putStrLn ""
  putStrLn "  uithub-cli repos [opts]         Show repos in uithub.toml"
  putStrLn "    -g, --global                  Show global uithub.toml"
  putStrLn ""
  putStrLn "  uithub-cli config set-key <key> Set API key"
  putStrLn "  uithub-cli config show          Show current config"
  putStrLn ""
  putStrLn "Examples:"
  putStrLn "  uithub-cli fetch -s anthropics/claude-code"
  putStrLn "  uithub-cli install"
  putStrLn "  uithub-cli get owner/repo"

-- Parse fetch flags and return (FetchOpts, remaining args)
parseFetchFlags : List String -> (FetchOpts, List String)
parseFetchFlags args = go defaultFetchOpts args
  where
    go : FetchOpts -> List String -> (FetchOpts, List String)
    go opts [] = (opts, [])
    go opts ("-s" :: rest) = go ({ saveLocal := True } opts) rest
    go opts ("--save" :: rest) = go ({ saveLocal := True } opts) rest
    go opts ("-g" :: rest) = go ({ saveGlobal := True } opts) rest
    go opts ("--global" :: rest) = go ({ saveGlobal := True } opts) rest
    go opts args = (opts, args)

-- Check if args contain global flag
hasGlobalFlag : List String -> Bool
hasGlobalFlag args = elem "-g" args || elem "--global" args

covering
parseArgs : List String -> IO ()
-- fetch with options
parseArgs ("fetch" :: rest) =
  let (opts, remaining) = parseFetchFlags rest
  in case remaining of
       [url] => cmdFetchWithOpts opts url
       _ => printUsage
-- install
parseArgs ["install"] = cmdInstall defaultInstallOpts
parseArgs ["install", "-g"] = cmdInstall (MkInstallOpts True)
parseArgs ["install", "--global"] = cmdInstall (MkInstallOpts True)
-- repos
parseArgs ["repos"] = cmdShowRepos False
parseArgs ["repos", "-g"] = cmdShowRepos True
parseArgs ["repos", "--global"] = cmdShowRepos True
-- existing commands
parseArgs ["get", url] = cmdGet url
parseArgs ["update", url] = cmdUpdate url
parseArgs ["list"] = cmdList
parseArgs ["config", "set-key", key] = cmdSetKey key
parseArgs ["config", "show"] = cmdShowConfig
parseArgs _ = printUsage

covering
main : IO ()
main = do
  args <- getArgs
  case args of
    _ :: rest => parseArgs rest
    [] => printUsage
