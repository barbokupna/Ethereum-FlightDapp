
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error, result);
            display('Operational Status', 'Check if contract is operational', [{ label: 'Operational Status', error: error, value: result }]);
        });
        contract.getRegisteredAirlines((error, result) => {
            console.log(result);
            console.log('getRegisteredAirlines', error, result[0]);

            let g = DOM.elid('registeredAirlines');
            result.forEach((airlineaddress) => {
                displayList(airlineaddress, airlineaddress, g);
            });
        });

        contract.getActivatedAirlines((error, result) => {
            console.log(result);
            //  console.log('getActivatedAirlines', error, result[0]);
            if (result == null) {
                console.log('getActivatedAirlinesNULL');
            }
            else {
                let g = DOM.elid('activatedAirlines');
                result.forEach((airlineaddress) => {
                    displayList(airlineaddress, airlineaddress, g);
                });
            }
        });

        contract.getRegisteredFlights((error, result) => {
            console.log('getRegisteredFlights');
            // console.log('getRegisteredFlights', error, result[0]);
            if (result == null) {
                console.log('getRegisteredFlightsNULL');
            }
            else {
                let g = DOM.elid('registeredFlights');
                result.forEach((airlineaddress) => {
                    displayList(airlineaddress, airlineaddress, g);
                });
            }
        });

        // User-submitted transactions 
        DOM.elid('register-airline').addEventListener('click', () => {
            let address = DOM.elid('address').value;
            let name = DOM.elid('name').value;
            // Write transaction
            contract.registerAirline(address, name, (error, result) => {
                if (!error) {
                    console.log('registerAirline OK', result);
                    displayList(address, address, DOM.elid("registeredAirlines"));
                }
                else {
                    console.log('registerAirline ERROR', error);
                }
            });
        });

        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [{ label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp }]);
            });
        })


        DOM.elid('fund-airline').addEventListener('click', () => {
            let amount = DOM.elid('amount').value
            var select = document.getElementById('registeredAirlines');
            var value = select.options[select.selectedIndex].value;

            contract.fundAirline(value, amount, (error, result) => {
                console.log('fundAirline', error, result);
                if (!error) {
                    // TODO Update Active Airlines
                }
            });
        });


        DOM.elid('register-flight').addEventListener('click', () => {
            let number = DOM.elid('flightNumber').value;
            // Write transaction
            contract.registerFlight(number, (error, result) => {
                console.log('registerFlight', error, result);
                if (!error) {

                }
            });
        });



    });

})();

function displayList(txt, value, parentEl) {
    let el = DOM.option();
    el.text = txt;
    el.value = value;
    parentEl.add(el);
}

function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
        row.appendChild(DOM.div({ className: 'col-sm-8 field-value' }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







