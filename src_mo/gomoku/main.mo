import Array "mo:base/Array";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Prim "mo:prim";
import Principal "mo:base/Principal";


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

func update_fifo_player_list(fifo_players: [var PlayerName], name: PlayerName) {
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
  remove(fifo_players, name);
  add(fifo_players, name);
};

let update_recent_players = update_fifo_player_list;

func player_state_to_view(player: PlayerState): PlayerView {
  { name = player.name; score = player.score; }
};

actor {
  // We use stable var to help keeping player data through upgrades.
  // This is necessary at the moment because HashMap cannot be made stable.
  // We also forego the requirement of persisting games, which is not as
  // crucial as keeping player accounts and scores.
  stable var accounts : [(PlayerId, PlayerState)] = [];

  // Player database is initiated from the stable accounts.
  let players : Players = {
    id_map = HashMap.fromIter<PlayerId, PlayerState>(
      accounts.vals(), accounts.size(), func (x, y) { x == y }, Principal.hash
    );
    name_map = HashMap.fromIter<PlayerName, PlayerId>(
      Iter.map<(PlayerId, PlayerState), (PlayerName, PlayerId)>(
        accounts.vals(), func ((id, state)) { (to_lowercase(state.name), id) }
      ), accounts.size(), func (x, y) { x == y }, Text.hash
    );
  };
  
  let recent_players : [var PlayerName] = Array.init<PlayerName>(10, "");

  func lookup_id_by_name(name: PlayerName) : ?PlayerId {
    players.name_map.get(to_lowercase(name))
  };

  func insert_new_player(id: PlayerId, name_: PlayerName) : PlayerState {
    let player = { name = name_; var score = 0; };
    players.id_map.put(id, player);
    players.name_map.put(to_lowercase(name_), id);
    player
  };

  func lookup_player_by_id(id: PlayerId) : ?PlayerState {
    players.id_map.get(id)
  };
  public func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  // Player login/registration. If the caller is not already found in the player database,
  // a new account is created with the given name. Otherwise the given name is ignored.
  // Return player info if the player is found or successfully registered, or an registration
  // error.
  public shared(msg) func register(name: Text): async Result<PlayerView, RegistrationError> {
      let player_id = msg.caller;
      switch (lookup_player_by_id(player_id), valid_name(name)) {
          case (?player, _) {
              update_recent_players(recent_players, player.name);
              #ok(player_state_to_view(player))
          };
          case (_, false) (#err(#InvalidName));
          case (null, true) {
              switch (lookup_id_by_name(name)) {
              case null {
                  let player = insert_new_player(player_id, name);
                  update_recent_players(recent_players, name);
                  #ok(player_state_to_view(player))
              };
              case (?_) (#err(#NameAlreadyExists));
              }
          }
      }
  };
};

