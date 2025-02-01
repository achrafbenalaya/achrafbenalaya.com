package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

type User struct {
	ID    int
	Name  string
	Email string
}

func getUser(db *sql.DB, userID int) (User, error) {
	var user User
	query := "SELECT id, name, email FROM users WHERE id = $1"
	err := db.QueryRow(query, userID).Scan(&user.ID, &user.Name, &user.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			return user, fmt.Errorf("no user found with id %d", userID)
		}
		return user, fmt.Errorf("error querying user: %v", err)
	}
	return user, nil
}

func main() {
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		log.Fatal("DATABASE_URL environment variable is not set")
	}

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("error opening database: %v", err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatalf("error connecting to the database: %v", err)
	}

	userID := 1
	user, err := getUser(db, userID)
	if err != nil {
		log.Fatalf("error getting user: %v", err)
	}

	fmt.Printf("User: %+v\n", user)
}
