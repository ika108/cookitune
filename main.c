#include <util/delay.h>
#include <avr/io.h>
#include <stdint.h>

#define setpinhigh(port,pin) ((port) |= (_BV(pin)))
#define setpinlow(port,pin) ((port) &= ~(_BV(pin)))
#define setpinout(ddr,pin) ((ddr) |= (_BV(pin)))
#define setpinin(ddr,pin) ((ddr) &= ~(_BV(pin)))
#define setportout(ddr) (ddr) = 0xff
#define setportin(ddr) (ddr) = 0x00
#define flippin(port,pin) ((port) ^= (_BV(pin)))
#define flipport(port) (port) = ~(port)

uint8_t getpindir( volatile uint8_t *ddr, uint8_t pin );
uint8_t getpinvalue( volatile uint8_t *port, uint8_t pin );
void blink (uint8_t number);

uint8_t getpindir( volatile uint8_t *ddr, uint8_t pin ) {
	int pinpow;
	pinpow = 1;
	for( ; pin > 0; pin-- ) {
		pinpow = pinpow * 2;
	}  
	return( ( *ddr & pinpow ) / pinpow );
}

uint8_t getpinvalue( volatile uint8_t *port, uint8_t pin ) {
	int pinpow;
	pinpow = 1;
	for( ; pin > 0; pin-- ) {
		pinpow = pinpow * 2;
	}  
	return( ( *port & pinpow ) / pinpow );
}

void blink (uint8_t number) {
        uint8_t i;
        for(i = 0; i == number; i++){
		setpinhigh(PORTA,0);
                _delay_ms(500);
		setpinlow(PORTA,0);
		_delay_ms(500);
        }
        return;
}

int main (void) {
	// setportin(DDRA);
	setpinout(DDRA,0);
	setpinhigh(PORTA,0);
	while(1){ 
		blink(5);	
	}
	return(0);
}


