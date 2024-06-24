#!/usr/bin/env bash

set -e

# Farben für Ausgaben definieren
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Variablen für Pfade und Zertifikat
BINARY_PATH=".build/release/builder"
DESTINATION_PATH="$HOME/ohmydahal/bin/builder"
CERTIFICATE="Developer ID Application: David Chevallier (L9JFMHXSB9)"
VERSION_FILE="version.txt"
VERSION_LOG="version_log.txt"
TEMPLATE_FILE="templates/BuildInfo.swift.template"
INFO_FILE="Sources/Builder/Helpers/BuildInfo.swift"

# Version, Commit-Slug und Build-Datum aus dem Git-Repository lesen
if [ -f $VERSION_FILE ]; then
    VERSION=$(cat $VERSION_FILE)
else
    VERSION="0.0.0"
fi

if [[ "$1" == "--new" ]]; then
    # Version erhöhen
    IFS='.' read -r -a version_parts <<< "$VERSION"
    version_parts[2]=$((version_parts[2] + 1))
    if [ ${version_parts[2]} -ge 10 ]; then
        version_parts[2]=0
        version_parts[1]=$((version_parts[1] + 1))
        if [ ${version_parts[1]} -ge 10 ]; then
            version_parts[1]=0
            version_parts[0]=$((version_parts[0] + 1))
        fi
    fi
    VERSION="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
    echo $VERSION > $VERSION_FILE
    echo "$VERSION - $(date +"%Y-%m-%d %H:%M:%S") - $USER" >> $VERSION_LOG
    
    COMMIT_SLUG=$(git rev-parse --short HEAD)
    BUILD_DATE=$(date +"%Y-%m-%d %H:%M:%S")

    # Erste Build-Informationen ohne Codesigning-Informationen erstellen
    sed -e "s/{{VERSION}}/$VERSION/" \
        -e "s/{{COMMITSUG}}/$COMMIT_SLUG/" \
        -e "s/{{BUILDDATE}}/$BUILD_DATE/" \
        -e "s/{{CODESIGNINGIDENTITY}}/NotYetSigned/" \
        -e "s|{{CODESIGNINGINFO}}|NotYetSigned|" \
        $TEMPLATE_FILE > $INFO_FILE
fi

# Build-Prozess starten
echo -e "${GREEN}Starte den Build-Prozess...${NC}"
if swift build -c release; then
    echo -e "${GREEN}Build erfolgreich!${NC}"
else
    echo -e "${RED}Build fehlgeschlagen!${NC}"
    exit 1
fi

if [[ "$1" == "--new" ]]; then
    # Binärdatei signieren
    echo -e "${GREEN}Signiere die Binärdatei...${NC}"
    if codesign --sign "$CERTIFICATE" --force --verbose "$BINARY_PATH"; then
        echo -e "${GREEN}Binärdatei erfolgreich signiert!${NC}"
    else
        echo -e "${RED}Fehler beim Signieren der Binärdatei!${NC}"
        exit 1
    fi

    # Signatur überprüfen und Informationen extrahieren
    echo -e "${GREEN}Überprüfe die Signatur...${NC}"
    if codesign --verify --verbose "$BINARY_PATH"; then
        echo -e "${GREEN}Signatur erfolgreich überprüft!${NC}"
    else
        echo -e "${RED}Fehler beim Überprüfen der Signatur!${NC}"
        exit 1
    fi

    # Codesigning Informationen extrahieren
    IDENTITY=$(codesign -dvv "$BINARY_PATH" 2>&1 | grep 'Authority=' | head -n 1 | sed 's/^.*Authority=//')
    INFO=$(codesign -dvv "$BINARY_PATH" 2>&1 | grep -A 4 "TeamIdentifier=")

    # Informationen speichern
    perl -0777 -pe "s/{{VERSION}}/$VERSION/; s/{{COMMITSUG}}/$COMMIT_SLUG/; s/{{BUILDDATE}}/$BUILD_DATE/; s/{{CODESIGNINGIDENTITY}}/$IDENTITY/; s|{{CODESIGNINGINFO}}|$INFO|" $TEMPLATE_FILE > $INFO_FILE

    # Erneuter Build-Prozess starten, um die finalen Informationen zu integrieren
    echo -e "${GREEN}Starte den erneuten Build-Prozess...${NC}"
    if swift build -c release; then
        echo -e "${GREEN}Build erfolgreich!${NC}"
    else
        echo -e "${RED}Erneuter Build fehlgeschlagen!${NC}"
        exit 1
    fi
fi

# Binärdatei kopieren
echo -e "${GREEN}Kopiere die Binärdatei...${NC}"
if cp "$BINARY_PATH" "$DESTINATION_PATH"; then
    echo -e "${GREEN}Binärdatei erfolgreich kopiert!${NC}"
else
    echo -e "${RED}Fehler beim Kopieren der Binärdatei!${NC}"
    exit 1
fi

echo -e "${GREEN}Build-Prozess abgeschlossen.${NC}"
