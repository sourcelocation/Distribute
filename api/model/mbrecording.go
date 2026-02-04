package model

type MBRecording struct {
	ID             int             `gorm:"primaryKey"`
	GID            string          `gorm:"column:gid"`
	Name           string          `gorm:"column:name"`
	ArtistCreditID int             `gorm:"column:artist_credit"`
	ArtistCredit   *MBArtistCredit `gorm:"foreignKey:ArtistCreditID;references:ID"`
	Length         int             `gorm:"column:length"`
}

func (MBRecording) TableName() string {
	return "recording"
}

type MBArtistCredit struct {
	ID   int    `gorm:"primaryKey"`
	Name string `gorm:"column:name"`
}

func (MBArtistCredit) TableName() string {
	return "artist_credit"
}
