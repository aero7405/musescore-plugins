// =============================================================================
// Hi-hat Notation Converter
//
// A plugin for Musescore to convert 'Musescore style' hi-hat notation to conventional hi-hat notation with playback.
// =============================================================================

import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    version: "1.0"
    title: "Hi-hat Notation Convert"
    description: "Convert hi-hat notation from Musescore style to conventional style with playback."
    categoryCode: "composing-arranging-tools"

    // hardcoding pitches for open and closed hi-hat notes
    property var closedHiHatPitch: 42;
    property var openHiHatPitch: 46;
    
    // defining mute symbols
    property var muteOpen: SymId.brassMuteOpen;
    property var muteClosed: SymId.brassMuteClosed;

    // adds open and closed mute symbols to hi-hat notes
    function toggleHihat() {
        var cursor = curScore.newCursor(); // get the selection
        cursor.rewind(2); // go to the end of the selection

        if(!cursor.segment) { // if nothing selected
            console.log("nothing selected");
            return;
        } else { // marking start and end of selection
            var endTick = cursor.tick;
            cursor.rewind(1);
            var startTick = cursor.tick;
        }

        // variables for storing previous value of isOpenHiHat and isClosedHiHat
        // initialised to -1 so that first chord is always processed
        var prevIsOpenHiHat = -1;
        var prevIsClosedHiHat = -1;
        // iterate over selection
        while(cursor.segment && cursor.tick < endTick) {
            // selecting current element
            var e = cursor.element;

            // checking if e exists and is a chord
            if(!e || e.type != Element.CHORD) {
                cursor.next();
                continue;
            }

            var isOpenHiHat = 0;
            var isClosedHiHat = 0;
            // iterate over notes in chord finding hi-hat notes
            for (var i = 0; i < e.notes.length; i++) {
                isOpenHiHat += (e.notes[i].pitch == openHiHatPitch);
                isClosedHiHat += (e.notes[i].pitch == closedHiHatPitch);
            } 

            // skipping if doesn't contain hi-hat
            if (!(isOpenHiHat || isClosedHiHat)) {
                console.log("skipping chord because it doesn't contain hi-hat");
                cursor.next();
                prevIsOpenHiHat = -1;
                prevIsClosedHiHat = -1;
                continue;
            }

            // if both are present just throw a tantrum
            if (isOpenHiHat && isClosedHiHat) {
                console.log("skipping chord because both open and closed hi-hat are present");
                cursor.next();
                prevIsOpenHiHat = -1;
                prevIsClosedHiHat = -1;
                continue;
            }

            // adding mute symbol if is hihat
            if ((prevIsClosedHiHat != isClosedHiHat && prevIsOpenHiHat) || 
                (prevIsOpenHiHat != isOpenHiHat && prevIsClosedHiHat)) {

                console.log("creating symbol");
                var articulation = newElement(Element.ARTICULATION);
                articulation.symbol = (isClosedHiHat) ? muteClosed : muteOpen;
                e.add(articulation);
            }
            // saving values of isOpenHiHat and isClosedHiHat
            prevIsOpenHiHat = isOpenHiHat;
            prevIsClosedHiHat = isClosedHiHat;

            // if is open hi-hat, change pitch to closed hi-hat and create invisible note with open hi-hat sound on other voice
            if (isOpenHiHat) {
                console.log("changing pitch of open hi-hat to closed hi-hat");
                // iterate over notes in chord finding open hi-hat notes
                for (var i = 0; i < e.notes.length; i++) {
                    if (e.notes[i].pitch == openHiHatPitch && e.notes[i].visible) {
                        // making existing note invisible (just for playback)
                        e.notes[i].visible = false;
                        // creating muted note at close hi-hat pitch
                        var note = newElement(Element.NOTE);
                        note.pitch = closedHiHatPitch;
                        note.play = false;
                        e.add(note);
                    }
                } 
            }

            // advancing to next element
            cursor.next();
        }
    }

    onRun: {
        curScore.startCmd();
        toggleHihat();
        curScore.endCmd();
    }
}