package store

import "gorm.io/gorm"

// Paginate fetches a paginated list of items of type T.
// page: 1-based page number
// limit: number of items per page
// order: SQL order clause (e.g. "created_at desc")
// preloads: list of associations to preload
func Paginate[T any](db *gorm.DB, page, limit int, order string, preloads []string) ([]T, bool, error) {
	var items []T
	offset := (page - 1) * limit
	// Fetch one extra item to check if there is a next page
	fetchLimit := limit + 1

	query := db.Order(order).Offset(offset).Limit(fetchLimit)

	for _, p := range preloads {
		query = query.Preload(p)
	}

	if err := query.Find(&items).Error; err != nil {
		return nil, false, err
	}

	hasNext := false
	if len(items) > limit {
		hasNext = true
		items = items[:limit] // Remove the extra item
	}

	return items, hasNext, nil
}
