
import L "lib";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import BigMap "canister:BigMap";

actor {
  // We use stable var to help keeping player data through upgrades.
  // This is necessary at the moment because HashMap cannot be made stable.
  // We also forego the requirement of persisting games, which is not as
  // crucial as keeping player accounts and scores.
  stable var accounts : [(L.PlayerId, L.PlayerState)] = [];

  // Player database is initiated from the stable accounts.
  let players : L.Players = {
    id_map = HashMap.fromIter<L.PlayerId, L.PlayerState>(
      accounts.vals(), accounts.size(), func (x, y) { x == y }, Principal.hash
    );
    name_map = HashMap.fromIter<L.PlayerName, L.PlayerId>(
      Iter.map<(L.PlayerId, L.PlayerState), (L.PlayerName, L.PlayerId)>(
        accounts.vals(), func ((id, state)) { (L.to_lowercase(state.name), id) }
      ), accounts.size(), func (x, y) { x == y }, Text.hash
    );
  };

  // let top_players : [var ?PlayerView] =
  //   init_top_players(
  //     Iter.map<(PlayerId, PlayerState), PlayerState>(
  //       accounts.vals(),
  //       func (x) { x.1 }
  //   ));
  
  let recent_players : [var L.PlayerName] = Array.init<L.PlayerName>(10, "");

  func lookup_id_by_name(name: L.PlayerName) : ?L.PlayerId {
    players.name_map.get(L.to_lowercase(name))
  };
  func lookup_player_by_id(id: L.PlayerId) : ?L.PlayerState {
    players.id_map.get(id)
  };
  func lookup_player_by_name(name: L.PlayerName) : ?L.PlayerState {
    switch (lookup_id_by_name(name)) {
      case null { null };
      case (?id) { lookup_player_by_id(id) };
    }
  };


  func insert_new_player(id: L.PlayerId, name_: L.PlayerName) : L.PlayerState {
    let player = { name = name_; var score = 0; };
    players.id_map.put(id, player);
    players.name_map.put(L.to_lowercase(name_), id);
    player
  };

  func update_player(id: L.PlayerId, name_: L.PlayerName) : L.PlayerState {
    let player = { name = name_; var score = 0; };
    players.id_map.put(id, player);
    players.name_map.put(L.to_lowercase(name_), id);
    player
  };

  
  public func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };

  // Player login/registration. If the caller is not already found in the player database,
  // a new account is created with the given name. Otherwise the given name is ignored.
  // Return player info if the player is found or successfully registered, or an registration
  // error.
  public shared(msg) func register(name: Text): async L.Result<L.PlayerView, L.RegistrationError> {
      let player_id = msg.caller;
      let playerIfExists : ?L.PlayerState = lookup_player_by_id(player_id);
      switch (playerIfExists, L.valid_name(name)) {
          case (?player, _) {
              let oldName: L.PlayerName = Option.unwrap(playerIfExists).name;
              let player = update_player(player_id, name);
              L.update_recent_players(recent_players, oldName, name);
              #ok(L.player_state_to_view(player))
          };
          case (_, false) (#err(#InvalidName));
          case (null, true) {
              switch (lookup_id_by_name(name)) {
              case null {
                  let player = insert_new_player(player_id, name);
                  L.update_recent_players(recent_players, name, name);
                  #ok(L.player_state_to_view(player))
              };
              case (?_) (#err(#NameAlreadyExists));
              }
          }
      }
  };

  public query func listAll(): async () {
    // Debug.print(debug_show(players));
    let entries = players.id_map.entries();
    for (entry in entries) {
      Debug.print(debug_show(entry));
    }
  };

  // List top/recent/available players.
  public query func list(): async L.ListResult {
    let names_to_view = func(arr: [var L.PlayerName], count: Nat) : [L.PlayerView] {
      Array.map<?L.PlayerView, L.PlayerView>(
        Array.filter<?L.PlayerView>(
          Array.tabulate<?L.PlayerView>(count, func(i) {
            Option.map<L.PlayerState, L.PlayerView>(
              lookup_player_by_name(arr[i]),
              L.player_state_to_view)
          }),
          Option.isSome),
        func(x) { Option.unwrap<L.PlayerView>(x) } )
    };
    let count_until = func<A>(arr: [var A], f: A -> Bool) : Nat {
       var n = 0;
       for (i in Iter.range(0, arr.size() - 1)) {
         if (f(arr[i])) { return n; };
         n := n + 1;
       };
       return n;
    };
    // let n_top = count_until<?PlayerView>(top_players, Option.isNull);
    let n_recent = count_until<L.PlayerName>(recent_players, func(x) { x=="" });
    // let n_available = count_until<PlayerName>(available_players, func(x) { x=="" });
    {
      // top = Array.tabulate<PlayerView>(n_top, func(i) { Option.unwrap(top_players[i]) });
      recent = names_to_view(recent_players, n_recent);
      // available = names_to_view(available_players, n_available);
    }
  };
};