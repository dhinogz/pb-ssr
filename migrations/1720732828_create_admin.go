package migrations

import (
	"github.com/pocketbase/dbx"
	"github.com/pocketbase/pocketbase/daos"
	m "github.com/pocketbase/pocketbase/migrations"
	"github.com/pocketbase/pocketbase/models"
	"github.com/pocketbase/pocketbase/tools/security"
)

func init() {
	m.Register(func(db dbx.Builder) error {
		dao := daos.New(db)

		collection, err := dao.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}

		record := models.NewRecord(collection)
		record.SetUsername("u_" + security.RandomStringWithAlphabet(5, "123456789"))
		record.SetPassword("pass123")
		record.Set("name", "Admin")
		record.Set("email", "admin@example.com")

		return dao.SaveRecord(record)
	}, func(db dbx.Builder) error { // optional revert operation
		dao := daos.New(db)

		record, err := dao.FindAuthRecordByEmail("users", "admin@example.com")
		if err != nil {
			return err
		}
		if record != nil {
			return dao.DeleteRecord(record)
		}

		// already deleted
		return nil
	})
}
