
import "package:agregator_kripto/features/crypto_list/bloc/crypto_list_bloc.dart";
import "package:agregator_kripto/repositories/crypto_coins/abstract_coins_repository.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:get_it/get_it.dart";
import "../widgets/widgets.dart";

class CryptoListScreen extends StatefulWidget {
  const CryptoListScreen({super.key, required this.title});
  final String title;

  @override
  State<CryptoListScreen> createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {


  final _cryptoListBloc = CryptoListBloc(GetIt.I<AbstractCoinsRepository>());


  @override
  void initState() {
    _cryptoListBloc.add(LoadCryptoList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Colors.yellow.shade500,
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _cryptoListBloc.add(LoadCryptoList());
        },
        child: BlocBuilder<CryptoListBloc, CryptoListState> (
          bloc: _cryptoListBloc,
          builder: (
              BuildContext context,
              CryptoListState state) {
            if (state is CryptoListLoaded) {
                    //const Center (child: CircularProgressIndicator())
                    return ListView.separated(
                    padding: EdgeInsets.only(top: 2, left: 10, bottom: 50),
                    itemCount: state.coinsList.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, i) {
                      final coin = state.coinsList[i];
                      return CryptoCoinTile(coin: coin);
                    }
                );



            }

            if (state is CryptoListLoadingFailure) {
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "OSHIBKA",
                      ),
                      const SizedBox(height: 35),
                      TextButton(
                          onPressed: (){
                            _cryptoListBloc.add(LoadCryptoList());
                          },
                          child: const Text("Rogaliki")
                      )
                    ],
                  )

              );

            }
            return const Center (child: CircularProgressIndicator()); }, ),
      )




    //
    //
    );
  }
}

