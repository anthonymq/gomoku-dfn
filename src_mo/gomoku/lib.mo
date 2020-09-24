import Result "mo:base/Result";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Prim "mo:prim";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

type Result<T,E> = Result.Result<T,E>;
type PlayerName = Text;
type PlayerId = Principal;

type Score = Nat;
type RegistrationError = {
  #InvalidName;
  #NameAlreadyExists;
};
type PlayerView = {
  name: PlayerName;
  score: Score;
};
type PlayerState = {
  name: PlayerName;
  var score: Score;
};
type Players = {
  id_map: HashMap.HashMap<PlayerId, PlayerState>;
  name_map: HashMap.HashMap<PlayerName, PlayerId>;
};
type ListResult = {
  // top: [PlayerView];
  recent: [PlayerView];
  // available: [PlayerView];
};

// Convert text to lower case
func to_lowercase(name: Text) : Text {
  var str = "";
  for (c in Text.toIter(name)) {
    let ch = if ('A' <= c and c <= 'Z') { Prim.word32ToChar(Prim.charToWord32(c) + 32) } else { c };
    str := str # Prim.charToText(ch);
  };
  str
};

// Check if player name is valid, which is defined as:
// 1. Between 2 and 10 characters long
// 2. Alphanumerical. Special characters like  '_' and '-' are also allowed.
func valid_name(name: Text): Bool {
  let str : [Char] = Iter.toArray(Text.toIter(name));
  if (str.size() < 2 or str.size() > 10) {
    return false;
  };
  for (i in Iter.range(0, str.size() - 1)) {
    let c = str[i];
    if (not ((c >= 'a' and c <= 'z') or
             (c >= 'A' and c <= 'Z') or
             (c >= '0' and c <= '9') or
             (c == '_' or c == '-'))) {
       return false;
    }
  };
  true
};

func update_fifo_player_list(fifo_players: [var PlayerName], oldName: PlayerName, newName:PlayerName) {
  let N = fifo_players.size();
  func remove(names: [var PlayerName], name: PlayerName) {
    for (i in Iter.range(0, N - 1)) {
      if (names[i] == name) {
        for (j in Iter.range(i, N - 2)) {
          names[j] := names[j + 1];
        };
        names[N-1] := "";
      }
    }
  };
  func add(names: [var PlayerName], name: PlayerName) {
    for (i in Iter.range(0, N - 1)) {
      if (fifo_players[i] == "") {
        fifo_players[i] := name;
        return;
      }
    };
    remove(names, names[0]);
    names[N-1] := name;
  };
  remove(fifo_players, oldName);
  add(fifo_players, newName);
};

let update_recent_players = update_fifo_player_list;

func player_state_to_view(player: PlayerState): PlayerView {
  { name = player.name; score = player.score; }
};

