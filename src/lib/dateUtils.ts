/**
 * Utilidades para manejo de fechas con timezone de América/Lima (UTC-5)
 */

const TIMEZONE = 'America/Lima';

/**
 * Obtiene la fecha actual en formato YYYY-MM-DD según el timezone de Lima
 */
export const getFechaActual = (): string => {
  const ahora = new Date();
  
  // Convertir a timezone de Lima
  const fechaLima = new Date(ahora.toLocaleString('en-US', { timeZone: TIMEZONE }));
  
  const year = fechaLima.getFullYear();
  const month = String(fechaLima.getMonth() + 1).padStart(2, '0');
  const day = String(fechaLima.getDate()).padStart(2, '0');
  
  return `${year}-${month}-${day}`;
};

/**
 * Obtiene la hora actual en formato HH:MM:SS según el timezone de Lima
 */
export const getHoraActual = (): string => {
  const ahora = new Date();
  
  // Convertir a timezone de Lima
  const fechaLima = new Date(ahora.toLocaleString('en-US', { timeZone: TIMEZONE }));
  
  const hours = String(fechaLima.getHours()).padStart(2, '0');
  const minutes = String(fechaLima.getMinutes()).padStart(2, '0');
  const seconds = String(fechaLima.getSeconds()).padStart(2, '0');
  
  return `${hours}:${minutes}:${seconds}`;
};

/**
 * Obtiene el día de la semana actual según el timezone de Lima (0 = Domingo, 6 = Sábado)
 */
export const getDiaSemanaActual = (): number => {
  const ahora = new Date();
  const fechaLima = new Date(ahora.toLocaleString('en-US', { timeZone: TIMEZONE }));
  return fechaLima.getDay();
};

/**
 * Obtiene la fecha y hora actual completa según el timezone de Lima
 */
export const getFechaHoraActual = () => {
  const ahora = new Date();
  const fechaLima = new Date(ahora.toLocaleString('en-US', { timeZone: TIMEZONE }));
  
  return {
    fecha: getFechaActual(),
    hora: getHoraActual(),
    diaSemana: fechaLima.getDay(),
    fechaCompleta: fechaLima
  };
};

/**
 * Formatea una fecha para mostrar en la UI
 */
export const formatearFecha = (fecha: string): string => {
  const [year, month, day] = fecha.split('-');
  return `${day}/${month}/${year}`;
};

/**
 * Formatea una hora para mostrar en la UI
 */
export const formatearHora = (hora: string): string => {
  return hora.substring(0, 8); // HH:MM:SS
};
