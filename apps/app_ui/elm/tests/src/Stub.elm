module Stub exposing (..)

import Common.Form as Form
import Common.Form.Field as Field
import Common.Role as Role
import Data.AuthToken exposing (AuthToken(..))
import Data.User as User exposing (User)
import Data.UserPhoto exposing (UserPhoto(..))


user : User
user =
    { id = 1
    , email = "email"
    , guardian_token = AuthToken "auth"
    , username = User.Username "name"
    , fullName = User.FullName "full name"
    , userPhoto = UserPhoto (Just "photo")
    , createdAt = "createdAt"
    , updatedAt = "updatedAt"
    }


form : msg -> List (List (Field.Data msg id)) -> Form.Data msg id
form submit fields =
    { validation = validFormValidationState
    , fields = fields
    , buttons = []
    , layoutType = Form.Standard
    , columnLayout = Form.OneColumn
    , onSubmit = submit
    }


validFormValidationState =
    { isValid = Form.Valid
    , message = Nothing
    , role = Just Role.Success
    }


validFieldValidationState =
    { isValid = Field.Valid
    , message = Nothing
    , role = Just Role.Success
    }


invalidFormValidationState =
    { isValid = Form.NotValid
    , message = Just "There are problems with this form. Please resolve them and click \"Save\""
    , role = Just Role.Danger
    }


invalidFieldValidationState =
    { isValid = Field.NotValid
    , message = Just "invalid"
    , role = Just Role.Danger
    }


textField : id -> String -> Field.Data msg id
textField id value =
    { dataType = Field.StringBasic
    , id = id
    , fieldType = Field.Text
    , label = Just "label"
    , value = value
    , min = Nothing
    , max = Nothing
    , size = Nothing
    , width = Nothing
    , validation = validFieldValidationState
    , onUpdate = Nothing
    , options = Nothing
    , optionsLoading = False
    , columnSizes = Nothing
    , required = True
    , readOnly = True
    , disabled = True
    , forceValue = True
    , invalidMessage = Just "invalid"
    }
