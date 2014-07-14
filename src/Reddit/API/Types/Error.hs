module Reddit.API.Types.Error
  (RedditError(..)) where

import Control.Applicative
import Data.Aeson
import Data.Monoid (mempty)
import Data.Text (Text)
import Data.Vector ((!?))
import qualified Data.Vector as V

data RedditError = RedditError Object
                 | CaptchaError Text
                 | CredentialsError
                 | RateLimitError Text
                 | NoSubredditSpecified
                 | NoURLSpecified
                 | NoName
                 | NoText Text
                 | AlreadySubmitted
                 | CommentDeleted
                 | BadSubredditName
                 deriving (Show)

instance FromJSON RedditError where
  parseJSON (Object o) = do
    Array errors <- o .: "json" >>= (.: "errors")
    case errors !? 0 of
      Just (Array e) -> case V.toList e of 
        String "WRONG_PASSWORD" : _ -> return CredentialsError
        String "USER_REQUIRED" : _ -> return CredentialsError
        String "RATELIMIT" : String d : _ -> return $ RateLimitError d
        String "SUBREDDIT_REQUIRED" : _ -> return NoSubredditSpecified
        String "ALREADY_SUB" : _ -> return AlreadySubmitted
        String "NO_URL" : _ -> return NoURLSpecified
        String "NO_NAME" : _ -> return NoName
        String "NO_TEXT" : _ : String f : _ -> return $ NoText f
        String "COMMENT_DELETED" : _ -> return CommentDeleted
        String "BAD_SR_NAME" : _ -> return BadSubredditName
        String "BAD_CAPTCHA" : _ -> CaptchaError <$> (o .: "json" >>= (.: "captcha"))
        _ -> return $ RedditError o
      _ -> mempty
  parseJSON _ = mempty
