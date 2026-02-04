package utils

// func BindAndValidate(c echo.Context, i interface{}) error {
// 	if err := c.Bind(i); err != nil {
// 		return echo.NewHTTPError(http.StatusBadRequest, "Invalid input format")
// 	}
// 	if err := c.Validate(i); err != nil {
// 		return echo.NewHTTPError(http.StatusBadRequest, "Validation failed").SetInternal(err)
// 	}
// 	return nil
// }

// func GetParamUUID(c echo.Context, paramName string) (uuid.UUID, error) {
// 	idStr := c.Param(paramName)
// 	id, err := uuid.Parse(idStr)
// 	if err != nil {
// 		return uuid.Nil, echo.NewHTTPError(http.StatusBadRequest, "Invalid "+paramName)
// 	}
// 	return id, nil
// }
